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
    output reg signed [19:0] img_num
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
                denom = (br * br) + (bi * bi); // Denom is Q.8

                if (denom != 0) begin
                    // (a+bi)/(c+di) = [(ac+bd) + (bc-ad)i] / (c^2+d^2)
                    temp_real = (ar * br) + (ai * bi); // Numerator is Q.8
                    temp_imag = (ai * br) - (ar * bi); // Numerator is Q.8

                    // To get a Q.4 result: (Q.8 << 4) / Q.8 = Q.4
                    // We use 48-bit temp to ensure the shift doesn't truncate data
                    real_num <= (temp_real <<< 4) / denom;
                    img_num  <= (temp_imag <<< 4) / denom;
                end else begin
                    real_num <= 0; // Overflow/Error indicator
                    img_num  <= 0;
                end
            end

            default: begin
                real_num <= 0;
                img_num  <= 0;
            end
        endcase
    end
endmodule