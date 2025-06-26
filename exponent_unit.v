module exponent_unit (
    input  [7:0] exp_a,
    input  [7:0] exp_b,
    input         op_sel,       // 0 for add (multiply op), 1 for subtract (divide op)
    output reg [7:0] exp_result,
    output reg overflow,
    output reg underflow
);
    reg signed [9:0] exp_temp;

    always @(*) begin
        if (op_sel == 1'b0) begin // Multiply operation: exp_a + exp_b - bias
            exp_temp = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 10'sd127;
        end else begin // Divide operation: exp_a - exp_b + bias
            exp_temp = $signed({1'b0, exp_a}) - $signed({1'b0, exp_b}) + 10'sd127;
        end

        overflow = 0;
        underflow = 0;

        if (exp_temp > 255) begin
            exp_result = 8'hFF;
            overflow = 1;
        end else if (exp_temp < 0) begin
            exp_result = 8'h00;
            underflow = 1;
        end else begin
            exp_result = exp_temp[7:0];
        end
    end
endmodule