`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2026 19:15:51
// Design Name: 
// Module Name: Calculate
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Calculate(
    input clk, 
    input [3:0] sw,
    input [6:0] real_1, img_1, real_2, img_2,   // 7-bit unsigned inputs

    output reg signed [19:0] real_num,          // Increased to 16-bit to prevent overflow
    output reg signed [19:0] img_num,
    output reg error = 0
);

    // Internal signed registers - widened for safety
    reg signed [19:0] ar, ai, br, bi;

    // Temporary registers widened to 48-bit to prevent shift/multiply truncation
    reg signed [47:0] temp_real, temp_imag, denom;

    // -----------------------------
    // COMBINATIONAL: Pre-scale inputs to Q12.4
    // -----------------------------
    always @(*) begin
    ar = real_1 <<< 4;   
    ai = img_1 <<< 4;
    br = real_2 <<< 4;
    bi = img_2 <<< 4;
    end

    // -----------------------------
    // SEQUENTIAL: Main Operations
    // -----------------------------
    always @(posedge clk) begin
        case(sw)

            // ADD (Scale stays Q12.4)
            4'b0001: begin
                real_num <= ar + br;
                img_num  <= ai + bi;
            end

            // SUB (Scale stays Q12.4)
            4'b0010: begin
                real_num <= ar - br;
                img_num  <= ai - bi;
            end

            // MULTIPLY
            4'b0100: begin
                // Result of (Q.4 * Q.4) is Q.8
                temp_real = (ar * br) - (ai * bi);
                temp_imag = (ar * bi) + (ai * br);

                // Shift back by 4 to return to Q12.4
                real_num <= temp_real >>> 4;
                img_num  <= temp_imag >>> 4;
            end

            // DIVIDE
            4'b1000: begin
                denom = (br * br) + (bi * bi);          // |b|^2  ? roughly Q24.8
            
                if (denom != 0) begin
                    error <= 0;
                    temp_real = (ar * br) + (ai * bi);  // real numerator ? Q24.8
                    temp_imag = (ai * br) - (ar * bi);  // imag numerator ? Q24.8
            
                    // === CRITICAL FIXES ===
                    // 1. Use wider intermediate to avoid overflow after << 4
                    // 2. Use arithmetic shift (<<<) for signed numbers
                    // 3. Perform the shift BEFORE division
                    real_num <= (temp_real <<< 4) / denom;   // (Q24.8 * 16) / Q24.8  ? Q12.4
                    img_num  <= (temp_imag <<< 4) / denom;
            
                end else begin
                    real_num <= 0;   // or 0, or a special "error" value like max negative
                    img_num  <= 0;
                    error <= 1;
                end
            end
            default: begin
                real_num <= 0;
                img_num  <= 0;
                error <= 0;
            end
        endcase
    end
endmodule