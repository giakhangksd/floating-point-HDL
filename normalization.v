module normalization(
    input         is_divide_op,     // 0 for multiply, 1 for divide
    input  [47:0] mult_mant_result, // Input from mantissa_multiplier
    input  [26:0] div_mant_quotient, // Input from mantissa_divider (Q[26].Q[25:0])
    input  [7:0]  exp_in,           // Current exponent sum/subtraction
    output reg [26:0] normalized_mant, // 24-bit mantissa (1.F) + 3 GRS bits
    output reg [7:0]  normalized_exp,
    output reg        norm_caused_underflow, // Flag if exponent becomes < 1 (denormal/zero)
    output reg        norm_caused_overflow   // Flag if exponent becomes > FF
);

    reg [7:0] shift_amount; // For more advanced normalization (not fully implemented here)

    integer i;
    reg found_msb;

    always @(*) begin
        normalized_exp = exp_in;
        norm_caused_underflow = 1'b0;
        norm_caused_overflow = 1'b0;

        if (is_divide_op) begin
            if (div_mant_quotient == 0) begin
                normalized_mant = 27'b0;
                normalized_exp = 8'h00;
                norm_caused_underflow = 1'b1;
            end else if (div_mant_quotient[26] == 1'b1) begin
                normalized_mant = div_mant_quotient;
            end else begin
                if (normalized_exp == 0) begin
                    normalized_mant = div_mant_quotient << 1;
                    norm_caused_underflow = (exp_in <= 1);
                end else if (exp_in == 8'hFF) begin
                    normalized_mant = div_mant_quotient;
                    norm_caused_overflow = 1'b1;
                end else begin
                    normalized_mant = div_mant_quotient << 1;
                    normalized_exp = exp_in - 1;
                    if (normalized_exp == 0 && exp_in == 1) begin
                        norm_caused_underflow = 1'b1;
                    end
                end
            end
        end else begin // Multiply operation
            if (mult_mant_result == 0) begin
                normalized_mant = 27'b0;
                normalized_exp = 8'h00;
                norm_caused_underflow = 1'b1;
            end else if (mult_mant_result[47]) begin
                normalized_mant = mult_mant_result[47:21];
                if (normalized_exp == 8'hFF) begin
                    norm_caused_overflow = 1'b1;
                end else begin
                    normalized_exp = exp_in + 1;
                end
            end else if (mult_mant_result[46]) begin
                normalized_mant = mult_mant_result[46:20];
            end else begin
                found_msb = 0;
                shift_amount = 0;
                normalized_mant = 27'b0;

                for (i = 45; i >= 20; i = i - 1) begin
                    if (mult_mant_result[i] && !found_msb) begin
                        shift_amount = 46 - i;
                        found_msb = 1;
                        if ((exp_in < shift_amount) && (exp_in != 0)) begin
                            norm_caused_underflow = 1'b1;
                            normalized_exp = 0;
                            normalized_mant = (mult_mant_result << shift_amount) >> (i - 19);
                        end 
								else if ((exp_in == 0) && (shift_amount > 0)) begin
										norm_caused_underflow = 1'b1;
										normalized_exp = 0;
								// Gradual underflow — shift enough to preserve denormals
										if (shift_amount <= 26) begin
											normalized_mant = mult_mant_result[45:19] >> shift_amount;
										end else begin
											normalized_mant = 27'b0; // too small, becomes 0
										end
								end
								else begin
                            normalized_mant = (mult_mant_result << shift_amount) >> 20;
                            normalized_exp = exp_in - shift_amount;
                            if ((normalized_exp == 0) && (exp_in >= 1) && (exp_in < shift_amount + 1)) begin
                                norm_caused_underflow = 1'b1;
                            end
                        end
                    end
                end

               if ((!found_msb) && (mult_mant_result != 0) && (normalized_mant == 0)) begin
							norm_caused_underflow = 1'b1;
							normalized_exp = 8'h00;
							normalized_mant = 27'b0;
               end else if (mult_mant_result == 0) begin
                    norm_caused_underflow = 1'b1;
                    normalized_exp = 8'h00;
                    normalized_mant = 27'b0;
                end
            end
        end

        if ((normalized_exp == 8'hFF) && (!norm_caused_overflow)) begin
            // Usually Inf/NaN state
        end else if ((normalized_exp == 8'h00) && (!norm_caused_underflow) && (exp_in > 0)) begin
            norm_caused_underflow = 1'b1;
        end
    end
endmodule
