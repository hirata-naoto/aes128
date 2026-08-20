// ============================================================
// sbox.sv
// S-box 参照モジュール（組合せROM）
// 1バイト入力 -> SBOX_TABLE[in_byte] を出力
// ============================================================
module sbox
    import aes_pkg::*;
(
    input  byte_t in_byte,
    output byte_t out_byte
);

    assign out_byte = SBOX_TABLE[in_byte];

    // ------------------------------------------------------------
    // SVA (即時アサーション): 入力が既知(non-X/Z)なら出力も既知であること
    // ------------------------------------------------------------
    always_comb begin
        assert (!$isunknown(in_byte) -> !$isunknown(out_byte))
            else $error("[SVA][sbox] in_byte=%02h が既知にも関わらず out_byte が不定値です", in_byte);
    end

    // ------------------------------------------------------------
    // SVA (エラボレーション時の静的チェック):
    // SBOX_TABLE が 0..255 の順列（全単射）であることを検証する。
    // シミュレーション開始時に1回だけ実行される。
    // ------------------------------------------------------------
    initial begin : sbox_bijectivity_check
        bit seen [0:255];
        for (int i = 0; i < 256; i++) begin
            seen[i] = 1'b0;
        end
        for (int i = 0; i < 256; i++) begin
            assert (!seen[SBOX_TABLE[i]])
                else $fatal(1, "[SVA][sbox] SBOX_TABLE に重複値があります (index=%0d, value=%02h)",
                            i, SBOX_TABLE[i]);
            seen[SBOX_TABLE[i]] = 1'b1;
        end
    end

endmodule
