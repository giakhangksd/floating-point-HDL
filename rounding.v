module rounding(
    input  [26:0] normalized_mant,   // 1.F + GRS (bit 26 is hidden '1', bits 2:0 are G,R,S)
    input  [7:0]  normalized_exp,
    output reg [22:0] rounded_mant,    // Final 23-bit fraction
    output reg [7:0]  rounded_exp,
    output reg        round_causes_overflow // To indicate if exponent needs to be FF
);

    reg [24:0] temp_mant_to_round; // Holds {1'b0, 1.F} from normalized_mant for rounding
    reg G, R, S, LSB;
    reg [7:0] shift_amt;
    reg [27:0] mant_with_grs; // Extra bits for denormal rounding
    reg sticky;
    integer i;

    always @(*) begin
        rounded_exp = normalized_exp;
        round_causes_overflow = 1'b0;

        // Extract G, R, S, LSB for normal rounding
        LSB = normalized_mant[3]; // Bit just before G
        G   = normalized_mant[2];
        R   = normalized_mant[1];
        S   = normalized_mant[0];

        // Prepare mantissa for rounding: 0 + 1.F (23-bit) = 25 bits
        temp_mant_to_round = {1'b0, normalized_mant[26:3]};

        // Round to Nearest, Ties to Even
        if (G && (R || S || LSB)) begin
            temp_mant_to_round = temp_mant_to_round + 1;
        end

        // Check if rounding caused an overflow into bit 24
        if (temp_mant_to_round[24]) begin
            rounded_mant = 23'h000000;
            if (rounded_exp == 8'hFE) begin
                rounded_exp = 8'hFF;
                round_causes_overflow = 1'b1;
            end else if (rounded_exp == 8'hFF) begin
                round_causes_overflow = 1'b1;
            end else begin
                rounded_exp = rounded_exp + 1;
            end
        end else begin
            rounded_mant = temp_mant_to_round[22:0];
        end

        // ---- Denormal Result Handling ----
        if (rounded_exp == 0 && normalized_exp > 0 && !round_causes_overflow) begin
            shift_amt = 8'd1 - normalized_exp;

            // Expand mantissa to 28 bits for shifting
            mant_with_grs = {1'b0, normalized_mant};

            // Compute sticky bit safely
            sticky = 1'b0;
            for (i = 0; i < 28; i = i + 1) begin
                if (i < shift_amt)
                    sticky = sticky | mant_with_grs[i];
            end

            // Perform shift
            mant_with_grs = mant_with_grs >> shift_amt;

            // Insert sticky bit
            mant_with_grs[0] = sticky;

            // Extract LSB, G, R, S for rounding
            LSB = mant_with_grs[3];
            G   = mant_with_grs[2];
            R   = mant_with_grs[1];
            S   = mant_with_grs[0];

            temp_mant_to_round = mant_with_grs[26:2]; // 25-bit

            if (G && (R || S || LSB)) begin
                temp_mant_to_round = temp_mant_to_round + 1;
            end

            rounded_mant = temp_mant_to_round[22:0];
            rounded_exp = 8'h00; // Denormal exponent
        end
    end

endmodule
