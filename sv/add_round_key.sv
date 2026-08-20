// ============================================================
// add_round_key.sv
// Rust の fn add_round_key(&self, state: &mut State, round_key: &State) に対応
// state と round_key の対応するバイトどうしを XOR する
// ============================================================
module add_round_key
    import aes_pkg::*;
(
    input  state_t state_in,
    input  state_t round_key,
    output state_t state_out
);

    genvar row, col;
    generate
        for (row = 0; row < 4; row++) begin : gen_row
            for (col = 0; col < 4; col++) begin : gen_col
                assign state_out[row][col] = state_in[row][col] ^ round_key[row][col];
            end
        end
    endgenerate

endmodule
