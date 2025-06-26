module top_fp_arithmetic (
    input CLOCK_50,
    input [15:0] SW,
    input [3:0] KEY, // KEY[0]=load, KEY[1]=op_sel, KEY[2]=reset
    output [7:0] LEDG,
    output [17:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    reg [15:0] a_low = 0, a_high = 0;
    reg [15:0] b_low = 0, b_high = 0;
    reg [1:0] load_stage = 0;
    reg key0_prev;
    reg [31:0] a, b, result;
    reg [1:0] calc_stage = 0;
    reg start_calc = 0;

    wire key0_fall = key0_prev & ~KEY[0];
    wire [31:0] b_combined = {b_high, b_low};
    wire [31:0] a_combined = {a_high, a_low};

    always @(posedge CLOCK_50) begin
        key0_prev <= KEY[0];

        if (~KEY[2]) begin
            load_stage <= 0;
            calc_stage <= 0;
            start_calc <= 0;
        end

        if (key0_fall) begin
            case (load_stage)
                2'd0: a_low  <= SW;
                2'd1: a_high <= SW;
                2'd2: b_low  <= SW;
                2'd3: begin
                    b_high <= SW;
                    a <= {a_high, a_low};
                    b <= {SW, b_low};
                    start_calc <= 1;
                end
            endcase
            load_stage <= load_stage + 1;
        end

        // Tách tính toán ra để không dính vào đường logic tổ hợp với KEY/SW
        if (start_calc) begin
            start_calc <= 0;
            if (KEY[1] == 1'b0)
                result <= a * b;
            else if (b != 32'd0)
                result <= a / b;
            else
                result <= 32'hFFFFFFFF;
        end
    end

    assign LEDR = result[17:0];
    assign LEDG = result[25:18];

    hex_display h0 (.in(result[3:0]),    .out(HEX0));
    hex_display h1 (.in(result[7:4]),    .out(HEX1));
    hex_display h2 (.in(result[11:8]),   .out(HEX2));
    hex_display h3 (.in(result[15:12]),  .out(HEX3));
    hex_display h4 (.in(result[19:16]),  .out(HEX4));
    hex_display h5 (.in(result[23:20]),  .out(HEX5));
    hex_display h6 (.in(result[27:24]),  .out(HEX6));
    hex_display h7 (.in(result[31:28]),  .out(HEX7));

endmodule
