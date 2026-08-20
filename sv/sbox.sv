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

endmodule
