// ============================================================
// bytes_to_state.sv
// Rust の fn bytes_to_state(&self, block: &[u8; 16]) -> State に対応
// state[i % 4][i / 4] = block[i]
// block_in のバイト i は block_in[127 - 8*i -: 8] (先頭バイトがMSB側)
// ============================================================
module bytes_to_state
    import aes_pkg::*;
(
    input  logic [127:0] block_in,
    output state_t        state_out
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_b2s
            assign state_out[i % 4][i / 4] = block_in[127 - i*8 -: 8];
        end
    endgenerate

endmodule
