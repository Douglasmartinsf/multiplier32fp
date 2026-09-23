`timescale 1ns/1ps
`ifndef CLK_PERIOD_NS
`define CLK_PERIOD_NS 4
`endif

module multiplier32fp_protocol_tb;
  localparam time PERIOD = `CLK_PERIOD_NS * 1ns;
  logic clk = 0, rst_n = 1, start_i = 0;
  logic [31:0] a_i = 0, b_i = 0, product_o;
  logic done_o, nan_o, infinit_o, overflow_o, underflow_o;
  logic pending = 0;
  logic [31:0] expected_input, pending_product, held_product = 0;
  logic [3:0] expected_flags, pending_flags;
  int checks = 0;
  multiplier32fp DUV (.*);
  always #(PERIOD/2) clk = ~clk;

`ifdef ANNOTATE_SDF
  initial begin
    string sdf_file;
    if (!$value$plusargs("SDF_FILE=%s", sdf_file)) $fatal(1, "SDF_FILE required");
    $sdf_annotate(sdf_file, DUV, , , "MAXIMUM");
  end
`endif

  // Inputs remain stable from the falling edge through this NBA/SDF settling delay.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending = 0;
      held_product = 0;
      #1;
      if ({done_o, product_o, nan_o, infinit_o, overflow_o, underflow_o} !== 37'b0)
        $fatal(1, "Reset did not clear outputs");
    end else begin
      #1;
      if (done_o !== pending) $fatal(1, "Invalid response latency");
      if (pending) begin
        if (product_o !== pending_product ||
            {nan_o, infinit_o, overflow_o, underflow_o} !== pending_flags)
          $fatal(1, "Response mismatch: got %h expected %h", product_o, pending_product);
        held_product = pending_product;
        checks++;
      end else if (product_o !== held_product ||
                   {nan_o, infinit_o, overflow_o, underflow_o} !== 4'b0)
        $fatal(1, "Idle outputs changed or flags remained asserted");
      pending = start_i;
      pending_product = expected_input;
      pending_flags = expected_flags;
    end
  end

  task automatic send(input logic valid, input logic [31:0] a, b, result,
                      input logic [3:0] flags);
    @(negedge clk);
    start_i = valid; a_i = a; b_i = b;
    expected_input = result; expected_flags = flags;
  endtask

  initial begin
    #1 rst_n = 0;
    repeat (2) @(negedge clk);
    rst_n = 1;
    send(1, 32'h3fc00000, 32'h40000000, 32'h40400000, 0); // 1.5 * 2
    send(1, 32'h80000000, 32'h40000000, 32'h80000000, 0); // negative zero
    send(1, 32'h7fc00000, 32'h3f800000, 0, 4'b1000);
    send(1, 32'hff800000, 32'h3f800000, 32'hff800000, 4'b0100);
    send(0, 0, 0, 0, 0);
    send(1, 32'h00000001, 32'h3f800000, 32'h00000001, 0);
    send(1, 32'h007fffff, 32'h40000000, 32'h00fffffe, 0);
    send(1, 32'h00800000, 32'h3f000000, 32'h00400000, 0);
    send(1, 32'h80800000, 32'h00800000, 0, 4'b0001);
    send(1, 32'hff7fffff, 32'h40000000, 32'h7fffffff, 4'b0010);
    send(1, 32'h7f7fffff, 32'h3f800000, 32'h7f7fffff, 0);
    send(1, 32'h3f800348, 32'h3f801382, 32'h3f8016ca, 0);
    send(0, 0, 0, 0, 0);
    send(0, 0, 0, 0, 0);
    // Abort a captured transaction before its response edge.
    send(1, 32'h3f800000, 32'h3f800000, 32'h3f800000, 0);
    @(negedge clk); rst_n = 0; start_i = 0;
    repeat (2) @(negedge clk);
    rst_n = 1;
    send(0, 0, 0, 0, 0);
    send(1, 32'h3f800000, 32'h40000000, 32'h40000000, 0);
    send(0, 0, 0, 0, 0);
    repeat (3) @(negedge clk);
    if (checks != 12) $fatal(1, "Expected 12 completed transactions, got %0d", checks);
    $display("TEST PASS protocol: %0d responses, reset flush and bubbles", checks);
    $finish;
  end
  initial begin
    #1000000;
    $fatal(1, "TEST TIMEOUT");
  end
endmodule
