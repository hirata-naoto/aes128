// ============================================================
// tb_aes128.sv
// Rust の #[test] fn test_nist_fips_197_vector() に対応するテストベンチ
//
// NIST FIPS-197 / NIST SP800-38A の公式テストベクタ(同一鍵・2ブロック分)で
// aes128_encrypt を検証する。
// SVA (concurrent assertion / cover property) による検証も行う。
// ============================================================
`timescale 1ns/1ps

module tb_aes128;

    // ---- クロック（組合せ回路の安定待ち・アサーションのサンプリングに使用） ----
    logic clk = 1'b0;
    always #5 clk = ~clk;

    // ---- DUT接続信号 ----
    logic [127:0] key;
    logic [127:0] plaintext;
    logic [127:0] ciphertext;
    logic [127:0] expected_ciphertext;
    logic         check_en; // アサーションを評価してよいタイミングを示す

    aes128_encrypt dut (
        .key       (key),
        .plaintext (plaintext),
        .ciphertext(ciphertext)
    );

    // ============================================================
    // SVA: concurrent assertions
    // ============================================================

    // 出力に不定値(X/Z)が伝搬していないこと
    property p_no_unknown;
        @(posedge clk) check_en |-> !$isunknown(ciphertext);
    endproperty
    assert_no_unknown: assert property (p_no_unknown)
        else $error("[SVA] ciphertext に不定値(X/Z)が含まれています: %h", ciphertext);

    // 既知解テストベクタ(KAT)との一致
    property p_known_answer;
        @(posedge clk) check_en |-> (ciphertext === expected_ciphertext);
    endproperty
    assert_known_answer: assert property (p_known_answer)
        else $error("[SVA] KATミスマッチ: 出力=%h 期待=%h", ciphertext, expected_ciphertext);

    // 平文と鍵が異なれば暗号文も平文と異なること（自明だが健全性チェックとして）
    property p_ciphertext_differs_from_plaintext;
        @(posedge clk) check_en |-> (ciphertext !== plaintext);
    endproperty
    assert_differs: assert property (p_ciphertext_differs_from_plaintext)
        else $error("[SVA] ciphertext が plaintext と一致しています（拡散不足の疑い）: %h", ciphertext);

    // KATが実際に何回評価されたかをカバレッジとして記録
    cover_known_answer: cover property (p_known_answer);

    // ============================================================
    // テストベクタ (NIST FIPS-197 Appendix B / NIST SP800-38A F.1.1)
    // ============================================================
    localparam int NUM_VECTORS = 2;
    logic [127:0] vec_key [0:NUM_VECTORS-1];
    logic [127:0] vec_pt  [0:NUM_VECTORS-1];
    logic [127:0] vec_ct  [0:NUM_VECTORS-1];

    initial begin
        // Block 1 (FIPS-197 Appendix B と同一)
        vec_key[0] = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        vec_pt[0]  = 128'h6bc1bee22e409f96e93d7e117393172a;
        vec_ct[0]  = 128'h3ad77bb40d7a3660a89ecaf32466ef97;

        // Block 2 (SP800-38A F.1.1 ECB-AES128、同一鍵)
        vec_key[1] = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        vec_pt[1]  = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
        vec_ct[1]  = 128'hf5d3d58503b9699de785895a96fdbaaf;
    end

    // ============================================================
    // テスト実行シーケンス
    // ============================================================
    int pass_count;
    int fail_count;

    initial begin
        check_en             = 1'b0;
        key                  = '0;
        plaintext            = '0;
        expected_ciphertext  = '0;
        pass_count           = 0;
        fail_count           = 0;

        @(negedge clk);

        for (int i = 0; i < NUM_VECTORS; i++) begin
            key                 = vec_key[i];
            plaintext           = vec_pt[i];
            expected_ciphertext = vec_ct[i];

            @(negedge clk); // 組合せ回路が安定するのを待つ
            check_en = 1'b1;

            @(posedge clk); // このエッジでSVAが評価される
            if (ciphertext === expected_ciphertext) begin
                pass_count++;
                $display("PASS[%0d]: 出力=%h", i, ciphertext);
            end else begin
                fail_count++;
                $display("FAIL[%0d]: 出力=%h 期待=%h", i, ciphertext, expected_ciphertext);
            end

            @(negedge clk);
            check_en = 1'b0;
        end

        $display("====================================");
        $display(" 合計: %0d件中 PASS=%0d FAIL=%0d", NUM_VECTORS, pass_count, fail_count);
        $display("====================================");

        #20;
        $finish;
    end

endmodule
