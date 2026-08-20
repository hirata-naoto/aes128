// ============================================================
// aes128_encrypt.sv
// Rust の impl Aes128 { pub fn encrypt(...) } に対応するトップモジュール
//
// 構成:
//   key_expansion  : 鍵 -> 11ラウンド鍵
//   bytes_to_state : 平文128bit -> state
//   add_round_key  : ラウンド0 (初期鍵加算)
//   [sub_bytes -> shift_rows -> mix_columns -> add_round_key] x 9 (ラウンド1-9)
//   [sub_bytes -> shift_rows -> add_round_key]                    (ラウンド10, MixColumnsなし)
//   state_to_bytes : state -> 暗号文128bit
//
// 完全組合せ回路（フルアンロール）として実装。
// ============================================================
module aes128_encrypt
    import aes_pkg::*;
(
    input  logic [127:0] key,
    input  logic [127:0] plaintext,
    output logic [127:0] ciphertext
);

    state_t round_keys [0:10];

    state_t state_in;
    state_t round_state [0:10];   // 各ラウンドのAddRoundKey後の状態
    state_t sb_out      [1:10];   // SubBytes出力
    state_t sr_out      [1:10];   // ShiftRows出力
    state_t mc_out      [1:9];    // MixColumns出力 (ラウンド10には無い)

    // ---- 鍵スケジュール ----
    key_expansion u_key_expansion (
        .key       (key),
        .round_keys(round_keys)
    );

    // ---- 平文 -> state ----
    bytes_to_state u_bytes_to_state (
        .block_in (plaintext),
        .state_out(state_in)
    );

    // ---- ラウンド0: 初期AddRoundKeyのみ ----
    add_round_key u_ark0 (
        .state_in (state_in),
        .round_key(round_keys[0]),
        .state_out(round_state[0])
    );

    // ---- ラウンド1〜9: SubBytes -> ShiftRows -> MixColumns -> AddRoundKey ----
    genvar r;
    generate
        for (r = 1; r <= 9; r++) begin : gen_main_rounds
            sub_bytes u_sub_bytes (
                .state_in (round_state[r-1]),
                .state_out(sb_out[r])
            );

            shift_rows u_shift_rows (
                .state_in (sb_out[r]),
                .state_out(sr_out[r])
            );

            mix_columns u_mix_columns (
                .state_in (sr_out[r]),
                .state_out(mc_out[r])
            );

            add_round_key u_add_round_key (
                .state_in (mc_out[r]),
                .round_key(round_keys[r]),
                .state_out(round_state[r])
            );
        end
    endgenerate

    // ---- ラウンド10 (最終ラウンド): SubBytes -> ShiftRows -> AddRoundKey ----
    sub_bytes u_sub_bytes_final (
        .state_in (round_state[9]),
        .state_out(sb_out[10])
    );

    shift_rows u_shift_rows_final (
        .state_in (sb_out[10]),
        .state_out(sr_out[10])
    );

    add_round_key u_add_round_key_final (
        .state_in (sr_out[10]),
        .round_key(round_keys[10]),
        .state_out(round_state[10])
    );

    // ---- state -> 暗号文 ----
    state_to_bytes u_state_to_bytes (
        .state_in (round_state[10]),
        .block_out(ciphertext)
    );

    // ------------------------------------------------------------
    // SVA (即時アサーション):
    // key / plaintext が既知値であれば ciphertext も既知値であること
    // (回路内でX/Zが意図せず伝搬していないことの確認)
    // ------------------------------------------------------------
    always_comb begin
        assert ((!$isunknown(key) && !$isunknown(plaintext)) -> !$isunknown(ciphertext))
            else $error("[SVA][aes128_encrypt] key/plaintextが既知にも関わらず ciphertext が不定値です: %h", ciphertext);
    end

endmodule
