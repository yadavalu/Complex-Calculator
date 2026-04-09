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
    
    input [6:0] real_1, img_1, real_2, img_2,  

    output reg signed [23:0] real_num,          
    output reg signed [23:0] img_num,
    output reg [3:0] ld,
    output reg error = 0
);

    
    reg signed [22:0] ar, ai, br, bi;

  
    reg signed [47:0] temp_real, temp_imag, denom;

    always @(*) begin
    ar = $signed({1'b0, real_1}) <<< 8;
    ai = $signed({1'b0, img_1}) <<< 8;
    br = $signed({1'b0, real_2}) <<< 8;
    bi = $signed({1'b0, img_2}) <<< 8;
    end

    always @(posedge clk) begin
        case(sw)

            // ADD 
            4'b0001: begin
                real_num <= ar + br;
                img_num  <= ai + bi;
                ld <= 4'b0001;
            end

            // SUB 
            4'b0010: begin
                real_num <= ar - br;
                img_num  <= ai - bi;
                ld <= 4'b0010;
            end

            // MULTIPLY
            4'b0100: begin
                ld <= 4'b0100;
                temp_real = ($signed({{25{ar[22]}}, ar}) * $signed({{25{br[22]}}, br})) - 
                            ($signed({{25{ai[22]}}, ai}) * $signed({{25{bi[22]}}, bi}));
                            
                temp_imag = ($signed({{25{ar[22]}}, ar}) * $signed({{25{bi[22]}}, bi})) + 
                            ($signed({{25{ai[22]}}, ai}) * $signed({{25{br[22]}}, br})); 
            
             
                real_num <= temp_real >>> 8;
                img_num  <= temp_imag >>> 8;
            end
            
            // DIVIDE
            4'b1000: begin
                ld <= 4'b1000;
                
                denom = ($signed({{25{br[22]}}, br}) * $signed(br)) + 
                        ($signed({{25{bi[22]}}, bi}) * $signed(bi));         
            
                if (denom != 0) begin
                    error <= 0;
                    
                   
                    temp_real = (($signed({{25{ar[22]}}, ar}) * $signed(br)) + 
                                 ($signed({{25{ai[22]}}, ai}) * $signed(bi))) <<< 8;
                                 
                    temp_imag = (($signed({{25{ai[22]}}, ai}) * $signed(br)) - 
                                 ($signed({{25{ar[22]}}, ar}) * $signed(bi))) <<< 8;  
                    
                 
                    real_num <= temp_real / denom;   
                    img_num  <= temp_imag / denom;
                end else begin
                    real_num <= 0;   
                    img_num  <= 0;
                    error <= 1;
                end
            end
            default: begin
                real_num <= 0;
                img_num  <= 0;
                error <= 0;
                ld <= 4'b0000;
            end
        endcase
    end
endmodule
