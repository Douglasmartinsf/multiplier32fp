`timescale 1ns/1ps

module multiplier32fp_flags_tb;

`ifndef CLK_PERIOD_NS
`define CLK_PERIOD_NS 4
`endif

`ifndef START_DELAY_NS
`define START_DELAY_NS 15
`endif

  localparam time CLK_PERIOD_NS = `CLK_PERIOD_NS * 1ns;
  localparam real START_DELAY_NS = `START_DELAY_NS;

  logic        clk_s                = 1'b0;
  logic        rst_n_s              = 1'b1;
  logic [31:0] a_s                  = 32'b0;
  logic [31:0] b_s                  = 32'b0;
  logic [31:0] product_s;
  logic        start_s              = 1'b0;
  logic        done_s;
  logic        nan_s;
  logic        infinit_s;
  logic        overflow_s;
  logic        underflow_s;

  int failure_count = 0;
  int case_count = 0;
  string       case_name_s;
  logic [31:0] expected_product_s;
  logic        expected_nan_s;
  logic        expected_infinit_s;
  logic        expected_overflow_s;
  logic        expected_underflow_s;

  multiplier32fp DUV (
    .clk         (clk_s),
    .rst_n       (rst_n_s),
    .a_i         (a_s),
    .b_i         (b_s),
    .product_o   (product_s),
    .start_i     (start_s),
    .done_o      (done_s),
    .nan_o       (nan_s),
    .infinit_o   (infinit_s),
    .overflow_o  (overflow_s),
    .underflow_o (underflow_s)
  );

`ifdef ANNOTATE_SDF
  initial begin : sdf_annotation
    string sdf_file;
    if (!$value$plusargs("SDF_FILE=%s", sdf_file))
      $fatal(1, "SDF_FILE is required for gate-level simulation");
    $sdf_annotate(sdf_file, DUV, , , "MAXIMUM");
  end
`endif

  initial begin
    #1 rst_n_s = 1'b0;
    repeat (2) @(negedge clk_s);
    rst_n_s = 1'b1;
  end

  always #(CLK_PERIOD_NS / 2) clk_s = ~clk_s;

  task automatic run_case(
    input string       name_i,
    input logic [31:0] a_value_i,
    input logic [31:0] b_value_i,
    input logic [31:0] product_expected_i,
    input logic        nan_expected_i,
    input logic        infinit_expected_i,
    input logic        overflow_expected_i,
    input logic        underflow_expected_i
  );
    @(negedge clk_s);
    case_count++;
    case_name_s          = name_i;
    a_s                  = a_value_i;
    b_s                  = b_value_i;
    expected_product_s   = product_expected_i;
    expected_nan_s       = nan_expected_i;
    expected_infinit_s   = infinit_expected_i;
    expected_overflow_s  = overflow_expected_i;
    expected_underflow_s = underflow_expected_i;

    start_s = 1'b1;
    @(posedge clk_s);
    #1 start_s = 1'b0;

    wait (done_s == 1'b1);
    #1;

    if (done_s !== 1'b1 || product_s !== expected_product_s ||
        nan_s !== expected_nan_s ||
        infinit_s !== expected_infinit_s ||
        overflow_s !== expected_overflow_s ||
        underflow_s !== expected_underflow_s) begin
      failure_count++;
      $error(
        "%s falhou: product_o=%h nan_o=%0b infinit_o=%0b overflow_o=%0b underflow_o=%0b",
        case_name_s,
        product_s,
        nan_s,
        infinit_s,
        overflow_s,
        underflow_s
      );
    end

    wait (done_s == 1'b0);
    #1;

    if (done_s !== 1'b0) begin
      failure_count++;
      $error("%s falhou: done_o ficou ativo por mais de 1 ciclo", case_name_s);
    end

    if (nan_s !== 1'b0 ||
        infinit_s !== 1'b0 ||
        overflow_s !== 1'b0 ||
        underflow_s !== 1'b0) begin
      failure_count++;
      $error(
        "%s falhou: alguma flag ficou ativa apos o ciclo permitido: nan_o=%0b infinit_o=%0b overflow_o=%0b underflow_o=%0b",
        case_name_s,
        nan_s,
        infinit_s,
        overflow_s,
        underflow_s
      );
    end

    repeat (2) @(posedge clk_s);
  endtask

  initial begin
    wait (rst_n_s == 1'b0);
    wait (rst_n_s == 1'b1);
    #(START_DELAY_NS);

    run_case("normal",      32'h3FC0_0000, 32'h4000_0000, 32'h4040_0000, 1'b0, 1'b0, 1'b0, 1'b0);
    run_case("nan_input",   32'h7FC0_0000, 32'h3F80_0000, 32'h0000_0000, 1'b1, 1'b0, 1'b0, 1'b0);
    run_case("nan_input_b", 32'h3F80_0000, 32'hFFC0_0000, 32'h0000_0000, 1'b1, 1'b0, 1'b0, 1'b0);
    run_case("inf_times_0", 32'h7F80_0000, 32'h0000_0000, 32'h0000_0000, 1'b1, 1'b0, 1'b0, 1'b0);
    run_case("inf_result",  32'h7F80_0000, 32'h3F80_0000, 32'h7F80_0000, 1'b0, 1'b1, 1'b0, 1'b0);
    run_case("neg_inf_result", 32'hFF80_0000, 32'h3F80_0000, 32'hFF80_0000, 1'b0, 1'b1, 1'b0, 1'b0);
    run_case("overflow",    32'h7F7F_FFFF, 32'h4000_0000, 32'h7FFF_FFFF, 1'b0, 1'b0, 1'b1, 1'b0);
    run_case("dirty_zero_pos", 32'h0000_0001, 32'h3F80_0000, 32'h0000_0001, 1'b0, 1'b0, 1'b0, 1'b0);
    run_case("dirty_zero_neg", 32'h8000_0001, 32'h3F80_0000, 32'h8000_0001, 1'b0, 1'b0, 1'b0, 1'b0);
    run_case("underflow",   32'h0080_0000, 32'h0080_0000, 32'h0000_0000, 1'b0, 1'b0, 1'b0, 1'b1);
    run_case("round_toward_zero", 32'h3F80_0348, 32'h3F80_1382, 32'h3F80_16CA, 1'b0, 1'b0, 1'b0, 1'b0);

    if (failure_count != 0) $fatal(1, "%0d flag checks failed", failure_count);
    $display("TEST PASS flags: %0d cases", case_count);
    $finish;
  end

  initial begin : watchdog
    #1000000;
    $fatal(1, "TEST TIMEOUT");
  end
endmodule
