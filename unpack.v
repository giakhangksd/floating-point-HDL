module unpack(
    input  [31:0] a, b,
    output        sign_a, sign_b,
    output [7:0]  exp_a, exp_b,
    output [23:0] mant_a, mant_b
);
    assign sign_a = a[31];
    assign exp_a  = a[30:23];
    assign mant_a = (exp_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};

    assign sign_b = b[31];
    assign exp_b  = b[30:23];
    assign mant_b = (exp_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
endmodule
