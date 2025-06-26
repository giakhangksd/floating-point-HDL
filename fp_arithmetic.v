module fp_arithmetic(
    input  [31:0] a_in,
    input  [31:0] b_in,
    input         op_sel, // 0 for multiply, 1 for divide
    output [31:0] result_out
);

    // Unpack stage
    wire sign_a, sign_b;
    wire [7:0] exp_a, exp_b;
    wire [23:0] mant_a, mant_b;

    unpack u_unpack (
        .a(a_in), .b(b_in),
        .sign_a(sign_a), .sign_b(sign_b),
        .exp_a(exp_a), .exp_b(exp_b),
        .mant_a(mant_a), .mant_b(mant_b)
    );

    // Sign logic
    wire sign_result = sign_a ^ sign_b;

    // Special case detection (logic remains similar to previous fp_unit)
    wire is_zero_a = (a_in[30:0] == 31'b0);
    wire is_zero_b = (b_in[30:0] == 31'b0);
    wire is_inf_a  = (exp_a == 8'hFF) && (mant_a[22:0] == 0);
    wire is_inf_b  = (exp_b == 8'hFF) && (mant_b[22:0] == 0);
    wire is_nan_a  = (exp_a == 8'hFF) && (mant_a[22:0] != 0);
    wire is_nan_b  = (exp_b == 8'hFF) && (mant_b[22:0] != 0);

    wire op_is_multiply = ~op_sel;
    wire op_is_divide   = op_sel;

    wire R_is_nan, R_is_inf, R_is_zero;
    // ... (logic R_is_nan, R_is_inf, R_is_zero nh? trong fp_unit tr??c) ...
    assign R_is_nan = is_nan_a || is_nan_b ||
                      (op_is_multiply && ((is_inf_a && is_zero_b) || (is_inf_b && is_zero_a))) ||
                      (op_is_divide   && ((is_zero_a && is_zero_b) || (is_inf_a && is_inf_b)));

    assign R_is_inf = (op_is_multiply && (is_inf_a || is_inf_b) && !( (is_inf_a && is_zero_b) || (is_inf_b && is_zero_a) )) ||
                      (op_is_divide   && ( (is_inf_a && !is_inf_b && !is_zero_b && !is_nan_b) ||
                                         (!is_inf_a && !is_zero_a && !is_nan_a && is_zero_b) ) );

    assign R_is_zero = (op_is_multiply && (is_zero_a || is_zero_b) && !( (is_inf_a && is_zero_b) || (is_inf_b && is_zero_a) )) ||
                       (op_is_divide   && ( (is_zero_a && !is_zero_b && !is_inf_b && !is_nan_b) ||
                                          (!is_inf_a && !is_nan_a && is_inf_b) ) );
    reg final_sign;

    // Exponent Unit
    wire [7:0] current_exp_calc_res;
    wire current_exp_ovf, current_exp_udf;

    exponent_unit u_exp_unit (
        .exp_a(exp_a),
        .exp_b(exp_b),
        .op_sel(op_sel), // Pass op_sel to select add or subtract
        .exp_result(current_exp_calc_res),
        .overflow(current_exp_ovf),
        .underflow(current_exp_udf)
    );

    // Mantissa Unit
    wire [47:0] mant_prod_val;
    wire [26:0] mant_div_val;

    mantissa_unit u_mant_unit (
        .mant_a(mant_a),
        .mant_b(mant_b),
        .product_result(mant_prod_val),
        .quotient_result(mant_div_val)
    );

    // Normalization stage
    wire [26:0] norm_mant;
    wire [7:0]  norm_exp;
    wire        norm_udf, norm_ovf;

    normalization u_norm (
        .is_divide_op(op_sel),
        .mult_mant_result(mant_prod_val),   // Pass product from mantissa_unit
        .div_mant_quotient(mant_div_val), // Pass quotient from mantissa_unit
        .exp_in(current_exp_calc_res),    // Pass result from exponent_unit
        .normalized_mant(norm_mant),
        .normalized_exp(norm_exp),
        .norm_caused_underflow(norm_udf),
        .norm_caused_overflow(norm_ovf)
    );

    // Rounding stage
    wire [22:0] round_mant;
    wire [7:0]  round_exp;
    wire        round_ovf;

    rounding u_round (
        .normalized_mant(norm_mant),
        .normalized_exp(norm_exp),
        .rounded_mant(round_mant),
        .rounded_exp(round_exp),
        .round_causes_overflow(round_ovf)
    );

    // Final Result Assembly
    reg [31:0] result_temp;

always @(*) begin
    if (R_is_nan) begin
        result_temp = 32'h7FC00000; // Quiet NaN

    end else if (R_is_inf || current_exp_ovf || norm_ovf || round_ovf || round_exp >= 8'hFF) begin
        final_sign = (op_is_divide && !is_inf_a && !is_nan_a && is_zero_b) ? sign_a : sign_result;
        result_temp = {final_sign, 8'hFF, 23'h000000}; // Infinity

    end else if (R_is_zero || current_exp_udf || (norm_udf && round_mant == 0)) begin
        result_temp = {sign_result, 8'h00, 23'h000000}; // True zero

    end else if (norm_udf) begin
        result_temp = {sign_result, 8'h00, round_mant}; // Denormal

    end else begin
        result_temp = {sign_result, round_exp, round_mant}; // Normal case
    end
end



    assign result_out = result_temp;

endmodule