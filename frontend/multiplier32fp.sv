`timescale 1ns/1ps

module multiplier32fp (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [31:0] a_i,
  input  logic [31:0] b_i,
  output logic [31:0] product_o,
  input  logic        start_i,
  output logic        done_o,
  output logic        nan_o,
  output logic        infinit_o,
  output logic        overflow_o,
  output logic        underflow_o
);

  localparam logic signed [10:0] EXP_BIAS       = 11'sd127;
  localparam logic signed [10:0] MIN_NORMAL_EXP = -11'sd126;

  function automatic logic signed [10:0] highest_one(input logic [47:0] data_i);
    highest_one = -11'sd1;

    for (int bit_idx_v = 47; bit_idx_v >= 0; bit_idx_v--) begin
      if (data_i[bit_idx_v] && highest_one < 11'sd0) begin
        highest_one = bit_idx_v;
      end
    end
  endfunction

  logic        valid_s1;
  logic        sign_s1;
  logic        special_s1;
  logic [31:0] special_product_s1;
  logic        special_nan_s1;
  logic        special_infinit_s1;
  logic        special_overflow_s1;
  logic        special_underflow_s1;
  logic        normal_pair_s1;
  logic signed [10:0] exp_sum_s1;
  logic [47:0] mant_product_s1;

  always_ff @(posedge clk or negedge rst_n) begin
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
    logic [47:0] norm_product_v;
    logic [47:0] subnormal_fraction_v;
    logic [23:0] main_v;
    logic [22:0] normal_fraction_v;
    logic        is_nan_a_v;
    logic        is_nan_b_v;
    logic        is_inf_a_v;
    logic        is_inf_b_v;
    logic        is_zero_a_v;
    logic        is_zero_b_v;
    logic        is_normal_finite_a_v;
    logic        is_normal_finite_b_v;

    if (!rst_n) begin
      valid_s1             <= 1'b0;
      sign_s1              <= 1'b0;
      special_s1           <= 1'b0;
      special_product_s1   <= 32'b0;
      special_nan_s1       <= 1'b0;
      special_infinit_s1   <= 1'b0;
      special_overflow_s1  <= 1'b0;
      special_underflow_s1 <= 1'b0;
      normal_pair_s1       <= 1'b0;
      exp_sum_s1           <= 11'sd0;
      mant_product_s1      <= 48'b0;
      product_o            <= 32'b0;
      done_o               <= 1'b0;
      nan_o                <= 1'b0;
      infinit_o            <= 1'b0;
      overflow_o           <= 1'b0;
      underflow_o          <= 1'b0;
    end else begin
      done_o      <= 1'b0;
      nan_o       <= 1'b0;
      infinit_o   <= 1'b0;
      overflow_o  <= 1'b0;
      underflow_o <= 1'b0;

      if (valid_s1) begin
        done_o <= 1'b1;

        if (special_s1) begin
          product_o   <= special_product_s1;
          nan_o       <= special_nan_s1;
          infinit_o   <= special_infinit_s1;
          overflow_o  <= special_overflow_s1;
          underflow_o <= special_underflow_s1;

        end else begin
          exp_norm_v = exp_sum_s1;

          if (normal_pair_s1) begin
            if (mant_product_s1[47]) begin
              normal_fraction_v = mant_product_s1[46:24];
              exp_norm_v++;
            end else begin
              normal_fraction_v = mant_product_s1[45:23];
            end

            if (exp_norm_v > 11'sd127) begin
              product_o  <= 32'h7FFF_FFFF;
              overflow_o <= 1'b1;

            end else if (exp_norm_v >= MIN_NORMAL_EXP) begin
              exp_biased_v = exp_norm_v + EXP_BIAS;
              product_o    <= {sign_s1, exp_biased_v, normal_fraction_v};

            end else begin
              subnormal_direct_shift_v = exp_sum_s1 + 11'sd103;

              if (subnormal_direct_shift_v >= 11'sd0) begin
                subnormal_fraction_v = mant_product_s1 << subnormal_direct_shift_v[5:0];
              end else if (subnormal_direct_shift_v >= -11'sd47) begin
                subnormal_shift_v    = -subnormal_direct_shift_v;
                subnormal_fraction_v = mant_product_s1 >> subnormal_shift_v;
              end else begin
                subnormal_fraction_v = 48'b0;
              end

              if (subnormal_fraction_v[22:0] != 23'b0) begin
                product_o <= {sign_s1, 8'b0, subnormal_fraction_v[22:0]};
              end else begin
                underflow_o <= 1'b1;
                product_o   <= 32'h0000_0000;
              end
            end

          end else begin
            highest_bit_v = highest_one(mant_product_s1);

            if (highest_bit_v == 11'sd47) begin
              norm_product_v = mant_product_s1 >> 1;
              exp_norm_v++;
            end else if (highest_bit_v < 11'sd46) begin
              shift_amount_v = 11'sd46 - highest_bit_v;
              norm_product_v = mant_product_s1 << shift_amount_v;
              exp_norm_v    -= shift_amount_v;
            end else begin
              norm_product_v = mant_product_s1;
            end

            if (exp_norm_v > 11'sd127) begin
              product_o  <= 32'h7FFF_FFFF;
              overflow_o <= 1'b1;

            end else if (exp_norm_v >= MIN_NORMAL_EXP) begin
              main_v       = norm_product_v[46:23];
              exp_biased_v = exp_norm_v + EXP_BIAS;
              product_o    <= {sign_s1, exp_biased_v, main_v[22:0]};

            end else begin
              subnormal_direct_shift_v = exp_sum_s1 + 11'sd103;

              if (subnormal_direct_shift_v >= 11'sd0) begin
                subnormal_fraction_v = mant_product_s1 << subnormal_direct_shift_v[5:0];
              end else if (subnormal_direct_shift_v >= -11'sd47) begin
                subnormal_shift_v    = -subnormal_direct_shift_v;
                subnormal_fraction_v = mant_product_s1 >> subnormal_shift_v;
              end else begin
                subnormal_fraction_v = 48'b0;
              end

              if (subnormal_fraction_v[22:0] != 23'b0) begin
                product_o <= {sign_s1, 8'b0, subnormal_fraction_v[22:0]};
              end else begin
                underflow_o <= 1'b1;
                product_o   <= 32'h0000_0000;
              end
            end
          end
        end
      end

      valid_s1             <= start_i;
      special_s1           <= 1'b0;
      special_product_s1   <= 32'b0;
      special_nan_s1       <= 1'b0;
      special_infinit_s1   <= 1'b0;
      special_overflow_s1  <= 1'b0;
      special_underflow_s1 <= 1'b0;
      normal_pair_s1       <= 1'b0;
      exp_sum_s1           <= 11'sd0;

      sign_v        = a_i[31] ^ b_i[31];
      exp_a_field_v = a_i[30:23];
      exp_b_field_v = b_i[30:23];
      mant_a_v      = {(exp_a_field_v != 8'h00), a_i[22:0]};
      mant_b_v      = {(exp_b_field_v != 8'h00), b_i[22:0]};

      mant_product_s1 <= mant_a_v * mant_b_v;

      if (start_i) begin
        is_nan_a_v           = (exp_a_field_v == 8'hFF) && (a_i[22:0] != 23'b0);
        is_nan_b_v           = (exp_b_field_v == 8'hFF) && (b_i[22:0] != 23'b0);
        is_inf_a_v           = (exp_a_field_v == 8'hFF) && (a_i[22:0] == 23'b0);
        is_inf_b_v           = (exp_b_field_v == 8'hFF) && (b_i[22:0] == 23'b0);
        is_zero_a_v          = (exp_a_field_v == 8'h00) && (a_i[22:0] == 23'b0);
        is_zero_b_v          = (exp_b_field_v == 8'h00) && (b_i[22:0] == 23'b0);
        is_normal_finite_a_v = (exp_a_field_v != 8'h00) && (exp_a_field_v != 8'hFF);
        is_normal_finite_b_v = (exp_b_field_v != 8'h00) && (exp_b_field_v != 8'hFF);

        sign_s1 <= sign_v;

        if (is_normal_finite_a_v && is_normal_finite_b_v) begin
          exp_sum_s1  <= $signed({3'b0, exp_a_field_v}) + $signed({3'b0, exp_b_field_v}) - (EXP_BIAS <<< 1);
          normal_pair_s1  <= 1'b1;

        end else if (is_nan_a_v || is_nan_b_v || ((is_inf_a_v && is_zero_b_v) || (is_zero_a_v && is_inf_b_v))) begin
          special_s1         <= 1'b1;
          special_product_s1 <= 32'h0000_0000;
          special_nan_s1     <= 1'b1;

        end else if (is_inf_a_v || is_inf_b_v) begin
          special_s1           <= 1'b1;
          special_product_s1   <= {sign_v, 8'hFF, 23'b0};
          special_infinit_s1   <= 1'b1;

        end else if (is_zero_a_v || is_zero_b_v) begin
          special_s1         <= 1'b1;
          special_product_s1 <= {sign_v, 31'b0};

        end else begin
          if (exp_a_field_v == 8'h00) begin
            mant_a_v         = {1'b0, a_i[22:0]};
            exp_unbiased_a_v = MIN_NORMAL_EXP;
          end else begin
            mant_a_v         = {1'b1, a_i[22:0]};
            exp_unbiased_a_v = $signed({3'b0, exp_a_field_v}) - EXP_BIAS;
          end

          if (exp_b_field_v == 8'h00) begin
            mant_b_v         = {1'b0, b_i[22:0]};
            exp_unbiased_b_v = MIN_NORMAL_EXP;
          end else begin
            mant_b_v         = {1'b1, b_i[22:0]};
            exp_unbiased_b_v = $signed({3'b0, exp_b_field_v}) - EXP_BIAS;
          end

          exp_sum_s1      <= exp_unbiased_a_v + exp_unbiased_b_v;
          normal_pair_s1  <= (exp_a_field_v != 8'h00) && (exp_b_field_v != 8'h00);
        end
      end
    end
  end

endmodule
