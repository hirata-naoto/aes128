// ============================================================
// mix_columns.sv
// Rust の fn mix_columns(&self, state: &mut State) に対応
// 各列 c に対して GF(2^8) 上の行列演算を行う
// ============================================================
module mix_columns
    import aes_pkg::*;
(
    input  state_t state_in,
    output state_t state_out
);

    genvar c;
    generate
        for (c = 0; c < 4; c++) begin : gen_col
            always_comb begin
                automatic byte_t s0, s1, s2, s3;

                s0 = state_in[0][c];
                s1 = state_in[1][c];
                s2 = state_in[2][c];
                s3 = state_in[3][c];

                state_out[0][c] = gmul(8'h02, s0) ^ gmul(8'h03, s1) ^ s2 ^ s3;
                state_out[1][c] = s0 ^ gmul(8'h02, s1) ^ gmul(8'h03, s2) ^ s3;
                state_out[2][c] = s0 ^ s1 ^ gmul(8'h02, s2) ^ gmul(8'h03, s3);
                state_out[3][c] = gmul(8'h03, s0) ^ s1 ^ s2 ^ gmul(8'h02, s3);
            end
        end
    endgenerate

endmodule
