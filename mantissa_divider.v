module mantissa_divider(
    input  [23:0] mant_a,        // Dividend's mantissa (1.Ma or 0.Ma)
    input  [23:0] mant_b,        // Divisor's mantissa (1.Mb or 0.Mb)
    output [26:0] mant_quotient  // Quotient: Q[26] is integer part (0 or 1), Q[25:0] is fractional part + GRS
);
    // To get 27 bits of precision (1 integer bit + 23 fractional + 3 GRS)
    // We can compute (mant_a * 2^k) / mant_b
    // If mant_a ~ mant_b, quotient ~ 1.0.  (mant_a * 2^26) / mant_b  ~ 2^26 (which is 1.00...0 in 27 bits)
    // If mant_a ~ 0.5*mant_b, quotient ~ 0.5. (mant_a * 2^26) / mant_b ~ 2^25 (which is 0.10...0 in 27 bits)

    // Ensure mant_b is not zero before this module is called by top FPU logic
    // Wire for extended dividend: 24 bits of mant_a + 26 zero bits for precision
    wire [49:0] extended_mant_a;
    assign extended_mant_a = {mant_a, 26'b0}; // Effectively mant_a * 2^26

    // The division result will be ~50 bits wide if using full width of extended_mant_a / mant_b
    // We are interested in the most significant ~27 bits.
    // Verilog's division A/B gives floor(A/B).
    wire [49:0] temp_quotient;
    assign temp_quotient = (mant_b == 0) ? {50{1'b1}} : (extended_mant_a / mant_b) ; // Avoid division by zero here, though FPU should catch it

    // The quotient mant_quotient should represent a value like Q. FFFFF... (GRS)
    // temp_quotient has its binary point effectively 26 places from the LSB
    // So, temp_quotient[26] is the integer bit (0 or 1)
    assign mant_quotient = temp_quotient[26:0];

endmodule