// First, ensure mantissa_multiplier and mantissa_divider are defined as before
// module mantissa_multiplier(...); endmodule
// module mantissa_divider(...); endmodule

module mantissa_unit (
    input  [23:0] mant_a,
    input  [23:0] mant_b,
    // op_sel is not strictly needed here if fp_unit MUXes outputs,
    // but can be used if this unit were to have a single output bus.
    // For this example, we output both and let fp_unit select.
    output [47:0] product_result,  // Output from multiplier
    output [26:0] quotient_result // Output from divider
);

    mantissa_multiplier u_mm (
        .mant_a(mant_a),
        .mant_b(mant_b),
        .mant_result(product_result)
    );

    mantissa_divider u_md (
        .mant_a(mant_a),
        .mant_b(mant_b),
        .mant_quotient(quotient_result)
    );

endmodule