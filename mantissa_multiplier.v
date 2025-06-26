module mantissa_multiplier(
    input  [23:0] mant_a,
    input  [23:0] mant_b,
    output [47:0] mant_result
);
    assign mant_result = mant_a * mant_b;
endmodule
