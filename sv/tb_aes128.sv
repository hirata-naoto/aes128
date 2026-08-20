// ============================================================
// tb_aes128.sv
// Rust の #[test] fn test_nist_fips_197_vector() に対応するテストベンチ
// NIST FIPS-197 公式テストベクタで aes128_encrypt を検証する
// ============================================================
`timescale 1ns/1ps

module tb_aes128;

    logic [127:0] key;
    logic [127:0] plaintext;
    logic [127:0] ciphertext;
    logic [127:0] expected_ciphertext;

    aes128_encrypt dut (
        .key       (key),
        .plaintext (plaintext),
        .ciphertext(ciphertext)
    );

    initial begin
        // NIST公式のテストベクタ
        key                 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        plaintext           = 128'h6bc1bee22e409f96e93d7e117393172a;
        expected_ciphertext = 128'h3ad77bb40d7a3660a89ecaf32466ef97;

        #10;

        if (ciphertext === expected_ciphertext) begin
            $display("PASS: NISTテストベクタの検証に成功しました！");
            $display("  出力: %h", ciphertext);
        end else begin
            $display("FAIL: 暗号化結果がNISTのテストベクタと一致しません！");
            $display("  出力: %h", ciphertext);
            $display("  期待: %h", expected_ciphertext);
        end

        $finish;
    end

endmodule
