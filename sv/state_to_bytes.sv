// ============================================================
// state_to_bytes.sv
// Rust の fn state_to_bytes(&self, state: &State) -> [u8; 16] に対応
// block[i] = state[i % 4][i / 4]
// ============================================================
module state_to_bytes
    import aes_pkg::*;
(
    input  state_t        state_in,
    output logic [127:0] block_out
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_s2b
            assign block_out[127 - i*8 -: 8] = state_in[i % 4][i / 4];
        end
    endgenerate

endmodule
