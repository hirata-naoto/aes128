// ============================================================
// shift_rows.sv
// Rust の fn shift_rows(&self, state: &mut State) に対応
//   row0 : シフトなし
//   row1 : 左に1バイト回転
//   row2 : 左に2バイト回転
//   row3 : 右に1バイト回転
// ============================================================
module shift_rows
    import aes_pkg::*;
(
    input  state_t state_in,
    output state_t state_out
);

    always_comb begin
        // Row 0: シフトなし
        state_out[0][0] = state_in[0][0];
        state_out[0][1] = state_in[0][1];
        state_out[0][2] = state_in[0][2];
        state_out[0][3] = state_in[0][3];

        // Row 1: 左に1バイト回転
        state_out[1][0] = state_in[1][1];
        state_out[1][1] = state_in[1][2];
        state_out[1][2] = state_in[1][3];
        state_out[1][3] = state_in[1][0];

        // Row 2: 左に2バイト回転
        state_out[2][0] = state_in[2][2];
        state_out[2][1] = state_in[2][3];
        state_out[2][2] = state_in[2][0];
        state_out[2][3] = state_in[2][1];

        // Row 3: 右に1バイト回転
        state_out[3][0] = state_in[3][3];
        state_out[3][1] = state_in[3][0];
        state_out[3][2] = state_in[3][1];
        state_out[3][3] = state_in[3][2];
    end

endmodule
