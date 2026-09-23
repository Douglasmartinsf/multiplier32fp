`timescale 1ns/1ps

module multiplier32fp_tb;

`ifndef CLK_PERIOD_NS
`define CLK_PERIOD_NS 4
`endif

`ifndef INPUT_APPLY_DELAY_NS
`define INPUT_APPLY_DELAY_NS 1
`endif

`ifndef START_DELAY_NS
`define START_DELAY_NS 15
`endif

  localparam time   CLK_PERIOD_NS = `CLK_PERIOD_NS * 1ns;
  localparam real   INPUT_APPLY_DELAY_NS = `INPUT_APPLY_DELAY_NS;
  localparam real   START_DELAY_NS = `START_DELAY_NS;
  string vector_file = "vetor.txt";
  localparam logic signed [10:0] EXP_BIAS       = 11'sd127;
  localparam logic signed [10:0] MIN_NORMAL_EXP = -11'sd126;

  logic        clk_s       = 1'b0;
  logic        rst_n_s     = 1'b1;
  logic [31:0] a_s         = 32'b0;
  logic [31:0] b_s         = 32'b0;
  logic [31:0] product_s;
  logic        start_s     = 1'b0;
  logic        done_s;
  logic        nan_s;
  logic        infinit_s;
  logic        overflow_s;
  logic        underflow_s;
  int          done_high_cycles_s = 0;
  int          vector_count_s     = 0;
  int          mismatch_count_s   = 0;
  int          clk_cycle_count_s  = 0;
  int          first_done_cycle_s = -1;
  int          last_done_cycle_s  = 0;

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

  always @(posedge clk_s or negedge rst_n_s) begin : cycle_counter
    if (!rst_n_s) begin
      clk_cycle_count_s <= 0;
    end else begin
      clk_cycle_count_s <= clk_cycle_count_s + 1;
    end
  end

  task automatic pulse_start;
    start_s = 1'b1;
    @(posedge clk_s);
    #1 start_s = 1'b0;
  endtask

  function automatic logic signed [10:0] highest_one_ref(input logic [47:0] data_i);
    highest_one_ref = -11'sd1;

    for (int bit_idx_v = 47; bit_idx_v >= 0; bit_idx_v--) begin
      if (data_i[bit_idx_v] && highest_one_ref < 11'sd0) begin
        highest_one_ref = bit_idx_v;
      end
    end
  endfunction

  task automatic expected_multiply(
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    output logic [31:0] product_o,
    output logic        nan_o,
    output logic        infinit_o,
    output logic        overflow_o,
    output logic        underflow_o
  );
    logic        sign_v;
    logic [7:0]  exp_a_field_v;
    logic [7:0]  exp_b_field_v;
    logic signed [10:0] exp_unbiased_a_v;
    logic signed [10:0] exp_unbiased_b_v;
    logic signed [10:0] exp_norm_v;
    logic signed [10:0] subnormal_direct_shift_v;
    logic [7:0]  exp_biased_v;
    logic [5:0]  shift_amount_v;
    logic [5:0]  subnormal_shift_v;
    logic signed [10:0] highest_bit_v;
    logic [23:0] mant_a_v;
    logic [23:0] mant_b_v;
    logic [47:0] mant_product_v;
    logic [47:0] norm_product_v;
    logic [47:0] subnormal_fraction_v;
    logic [23:0] main_v;
    logic [23:0] subnormal_v;
    logic        is_nan_a_v;
    logic        is_nan_b_v;
    logic        is_inf_a_v;
    logic        is_inf_b_v;
    logic        is_zero_a_v;
    logic        is_zero_b_v;

    sign_v        = a_i[31] ^ b_i[31];
    exp_a_field_v = a_i[30:23];
    exp_b_field_v = b_i[30:23];

    is_nan_a_v  = (exp_a_field_v == 8'hFF) && (a_i[22:0] != 23'b0);
    is_nan_b_v  = (exp_b_field_v == 8'hFF) && (b_i[22:0] != 23'b0);
    is_inf_a_v  = (exp_a_field_v == 8'hFF) && (a_i[22:0] == 23'b0);
    is_inf_b_v  = (exp_b_field_v == 8'hFF) && (b_i[22:0] == 23'b0);
    is_zero_a_v = (exp_a_field_v == 8'h00) && (a_i[22:0] == 23'b0);
    is_zero_b_v = (exp_b_field_v == 8'h00) && (b_i[22:0] == 23'b0);

    product_o   = 32'h0000_0000;
    nan_o       = 1'b0;
    infinit_o   = 1'b0;
    overflow_o  = 1'b0;
    underflow_o = 1'b0;

    if (is_nan_a_v || is_nan_b_v || ((is_inf_a_v && is_zero_b_v) || (is_zero_a_v && is_inf_b_v))) begin
      product_o = 32'h0000_0000;
      nan_o     = 1'b1;

    end else if (is_inf_a_v || is_inf_b_v) begin
      product_o = {sign_v, 8'hFF, 23'b0};
      infinit_o = 1'b1;

    end else if (is_zero_a_v || is_zero_b_v) begin
      product_o = {sign_v, 31'b0};

    end else if ((exp_a_field_v != 8'h00) && (exp_b_field_v != 8'h00)) begin
      mant_a_v       = {1'b1, a_i[22:0]};
      mant_b_v       = {1'b1, b_i[22:0]};
      mant_product_v = mant_a_v * mant_b_v;
      exp_norm_v     = $signed({3'b0, exp_a_field_v}) + $signed({3'b0, exp_b_field_v}) - (EXP_BIAS <<< 1);

      if (mant_product_v[47]) begin
        main_v = mant_product_v[47:24];
        exp_norm_v++;
      end else begin
        main_v = mant_product_v[46:23];
      end

      if (exp_norm_v > 11'sd127) begin
        product_o  = 32'h7FFF_FFFF;
        overflow_o = 1'b1;

      end else if (exp_norm_v >= MIN_NORMAL_EXP) begin
        exp_biased_v = exp_norm_v + EXP_BIAS;
        product_o    = {sign_v, exp_biased_v, main_v[22:0]};

      end else begin
        subnormal_direct_shift_v = $signed({3'b0, exp_a_field_v}) + $signed({3'b0, exp_b_field_v}) - (EXP_BIAS <<< 1) + 11'sd103;

        if (subnormal_direct_shift_v >= 11'sd0) begin
          subnormal_fraction_v = mant_product_v << subnormal_direct_shift_v[5:0];
        end else if (subnormal_direct_shift_v >= -11'sd47) begin
          subnormal_shift_v    = -subnormal_direct_shift_v;
          subnormal_fraction_v = mant_product_v >> subnormal_shift_v;
        end else begin
          subnormal_fraction_v = 48'b0;
        end

        if (subnormal_fraction_v[22:0] != 23'b0) begin
          product_o = {sign_v, 8'b0, subnormal_fraction_v[22:0]};
        end else begin
          product_o   = 32'h0000_0000;
          underflow_o = 1'b1;
        end
      end

    end else begin
      if (exp_a_field_v == 8'h00) begin
        mant_a_v         = {1'b0, a_i[22:0]};
        exp_unbiased_a_v = MIN_NORMAL_EXP;
      end else begin
        mant_a_v         = {1'b1, a_i[22:0]};
        exp_unbiased_a_v = exp_a_field_v - EXP_BIAS;
      end

      if (exp_b_field_v == 8'h00) begin
        mant_b_v         = {1'b0, b_i[22:0]};
        exp_unbiased_b_v = MIN_NORMAL_EXP;
      end else begin
        mant_b_v         = {1'b1, b_i[22:0]};
        exp_unbiased_b_v = exp_b_field_v - EXP_BIAS;
      end

      mant_product_v = mant_a_v * mant_b_v;
      highest_bit_v  = highest_one_ref(mant_product_v);
      exp_norm_v     = exp_unbiased_a_v + exp_unbiased_b_v;

      if (highest_bit_v == 11'sd47) begin
        norm_product_v = mant_product_v >> 1;
        exp_norm_v++;
      end else if (highest_bit_v < 11'sd46) begin
        shift_amount_v = 11'sd46 - highest_bit_v;
        norm_product_v = mant_product_v << shift_amount_v;
        exp_norm_v    -= shift_amount_v;
      end else begin
        norm_product_v = mant_product_v;
      end

      if (exp_norm_v > 11'sd127) begin
        product_o  = 32'h7FFF_FFFF;
        overflow_o = 1'b1;

      end else if (exp_norm_v >= MIN_NORMAL_EXP) begin
        main_v       = norm_product_v[46:23];
        exp_biased_v = exp_norm_v + EXP_BIAS;
        product_o    = {sign_v, exp_biased_v, main_v[22:0]};

      end else begin
        subnormal_direct_shift_v = exp_unbiased_a_v + exp_unbiased_b_v + 11'sd103;

        if (subnormal_direct_shift_v >= 11'sd0) begin
          subnormal_fraction_v = mant_product_v << subnormal_direct_shift_v[5:0];
        end else if (subnormal_direct_shift_v >= -11'sd47) begin
          subnormal_shift_v    = -subnormal_direct_shift_v;
          subnormal_fraction_v = mant_product_v >> subnormal_shift_v;
        end else begin
          subnormal_fraction_v = 48'b0;
        end

        if (subnormal_fraction_v[22:0] != 23'b0) begin
          product_o = {sign_v, 8'b0, subnormal_fraction_v[22:0]};
        end else begin
          product_o   = 32'h0000_0000;
          underflow_o = 1'b1;
        end
      end
    end
  endtask

  task automatic check_response(
    input int          vector_idx_i,
    input logic [31:0] a_i,
    input logic [31:0] b_i
  );
    logic [31:0] expected_product_v;
    logic        expected_nan_v;
    logic        expected_infinit_v;
    logic        expected_overflow_v;
    logic        expected_underflow_v;

    expected_multiply(
      a_i,
      b_i,
      expected_product_v,
      expected_nan_v,
      expected_infinit_v,
      expected_overflow_v,
      expected_underflow_v
    );

    if (done_s !== 1'b1 ||
        product_s !== expected_product_v ||
        nan_s !== expected_nan_v ||
        infinit_s !== expected_infinit_v ||
        overflow_s !== expected_overflow_v ||
        underflow_s !== expected_underflow_v) begin
      mismatch_count_s++;

      $error(
        "vetor %0d falhou: a=%h b=%h product_o=%h exp=%h done_o=%0b nan_o=%0b exp=%0b infinit_o=%0b exp=%0b overflow_o=%0b exp=%0b underflow_o=%0b exp=%0b",
        vector_idx_i,
        a_i,
        b_i,
        product_s,
        expected_product_v,
        done_s,
        nan_s,
        expected_nan_v,
        infinit_s,
        expected_infinit_v,
        overflow_s,
        expected_overflow_v,
        underflow_s,
        expected_underflow_v
      );
    end
  endtask

  always @(posedge clk_s or negedge rst_n_s) begin : done_width_monitor
    if (!rst_n_s) begin
      done_high_cycles_s <= 0;
    end else begin
      #1;

      if (done_s) begin
        done_high_cycles_s <= done_high_cycles_s + 1;

        if (first_done_cycle_s < 0) begin
          first_done_cycle_s <= clk_cycle_count_s;
        end

        last_done_cycle_s <= clk_cycle_count_s;


      end else begin
        done_high_cycles_s <= 0;
      end
    end
  end

  initial begin : stimulus_proc
    int         vector_file_v;
    int         read_count_v;
    int         effective_cycles_v;
    logic [31:0] next_a_v;
    logic [31:0] next_b_v;

    if ($value$plusargs("VECTOR_FILE=%s", vector_file)) begin end
    vector_file_v = $fopen(vector_file, "r");
    if (vector_file_v == 0) begin
      $fatal(1, "Nao foi possivel abrir %s", vector_file);
    end

    wait (rst_n_s == 1'b0);
    wait (rst_n_s == 1'b1);
    #(START_DELAY_NS);

    forever begin
      read_count_v = $fscanf(vector_file_v, "%h %h\n", next_a_v, next_b_v);
      if (read_count_v != 2) begin
        if (read_count_v != -1) $fatal(1, "Malformed vector input");
        $fclose(vector_file_v);

        if (vector_count_s == 0) begin
          $fatal(1, "vetor.txt vazio ou invalido");
        end

        if (mismatch_count_s == 0) begin
          effective_cycles_v = last_done_cycle_s - first_done_cycle_s + 1;
          $display("TEST PASS vectors: %0d", vector_count_s);
          $display("Ciclos efetivos do vetor: %0d", effective_cycles_v);

`ifdef POWER_2X_HOLD
          $display("Modo POWER_2X_HOLD: mantendo as ultimas entradas por mais %0d ciclos.", effective_cycles_v);
          repeat (effective_cycles_v) @(posedge clk_s);
          $display("Fim do intervalo POWER_2X_HOLD em %0t.", $time);
`endif
        end else begin
          $fatal(1, "%0d de %0d vetores falharam.", mismatch_count_s, vector_count_s);
        end

        $finish;
      end

      vector_count_s++;
      @(negedge clk_s);
      a_s = next_a_v;
      b_s = next_b_v;

      pulse_start();
      wait (done_s == 1'b1);
      #1;
      check_response(vector_count_s, next_a_v, next_b_v);

      wait (done_s == 1'b0);

      repeat (2) @(posedge clk_s);
      #(INPUT_APPLY_DELAY_NS);
    end
  end

  initial begin : watchdog
    #1000000;
    $fatal(1, "TEST TIMEOUT");
  end
endmodule
