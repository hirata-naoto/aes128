// ============================================================
// key_expansion.sv
// Rust の fn key_expansion(key: &[u8; 16]) -> [State; 11] に対応
//
// 128bit鍵から4バイトの word を w[0..43] まで生成し、
// 11個のラウンド鍵 (state_t) round_keys[0..10] に詰め直す。
// i % 4 == 0 のとき RotWord -> SubWord -> Rcon XOR を行う点も
// Rust実装と同一のロジック。
// ============================================================
module key_expansion
    import aes_pkg::*;
(
    input  logic [127:0] key,
    output state_t        round_keys [0:10]
);

    byte_t w [0:43][0:3];

    always_comb begin
        automatic byte_t temp [0:3];
        automatic byte_t t;

        // 最初の4ワードは鍵をそのまま4バイトずつ切り出す
        for (int i = 0; i < 4; i++) begin
            w[i][0] = key[127 - (4*i)   * 8 -: 8];
            w[i][1] = key[127 - (4*i+1) * 8 -: 8];
            w[i][2] = key[127 - (4*i+2) * 8 -: 8];
            w[i][3] = key[127 - (4*i+3) * 8 -: 8];
        end

        // 残り40ワードを生成
        for (int i = 4; i < 44; i++) begin
            temp[0] = w[i-1][0];
            temp[1] = w[i-1][1];
            temp[2] = w[i-1][2];
            temp[3] = w[i-1][3];

            if (i % 4 == 0) begin
                // RotWord
                t       = temp[0];
                temp[0] = temp[1];
                temp[1] = temp[2];
                temp[2] = temp[3];
                temp[3] = t;

                // SubWord
                temp[0] = SBOX_TABLE[temp[0]];
                temp[1] = SBOX_TABLE[temp[1]];
                temp[2] = SBOX_TABLE[temp[2]];
                temp[3] = SBOX_TABLE[temp[3]];

                // Rcon
                temp[0] = temp[0] ^ RCON[i/4];
            end

            w[i][0] = w[i-4][0] ^ temp[0];
            w[i][1] = w[i-4][1] ^ temp[1];
            w[i][2] = w[i-4][2] ^ temp[2];
            w[i][3] = w[i-4][3] ^ temp[3];
        end

        // word 配列 -> ラウンド鍵 (state_t[row][col] = w[r*4+c][row])
        for (int r = 0; r < 11; r++) begin
            for (int c = 0; c < 4; c++) begin
                for (int row = 0; row < 4; row++) begin
                    round_keys[r][row][c] = w[r*4 + c][row];
                end
            end
        end
    end

endmodule
