// ============================================================
// sub_bytes.sv
// Rust の fn sub_bytes(&self, state: &mut State) に対応
// state の全16バイトそれぞれに sbox モジュールを適用する
// ============================================================
module sub_bytes
    import aes_pkg::*;
(
    input  state_t state_in,
    output state_t state_out
);

    genvar row, col;
    generate
        for (row = 0; row < 4; row++) begin : gen_row
            for (col = 0; col < 4; col++) begin : gen_col
                sbox u_sbox (
                    .in_byte (state_in[row][col]),
                    .out_byte(state_out[row][col])
                );
            end
        end
    endgenerate

endmodule
