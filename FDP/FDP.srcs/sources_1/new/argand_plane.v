`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2026 13:52:45
// Design Name: 
// Module Name: argand_plane
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


module argand_plane(
    input clk_25MHz,
    input clk_6p25MHz,
    input [6:0] RE,
    input [6:0] IM,
    output [7:0] JC
    );
    
    wire my_frame_begin, my_sending_pixel, my_sample_pixel;
    wire [12:0] my_pixel_index;
    reg [15:0] oled_colour = 16'b11111_111111_11111;
    wire [6:0] x;
    wire [5:0] y;
    
    Oled_Display oled(
        .clk(clk_6p25MHz), .reset(0), .frame_begin(my_frame_begin), .sending_pixels(my_sending_pixel),
        .sample_pixel(my_sample_pixel), .pixel_index(my_pixel_index), .pixel_data(oled_colour), .cs(JC[0]), .sdin(JC[1]), .sclk(JC[3]), .d_cn(JC[4]), .resn(JC[5]), .vccen(JC[6]),
        .pmoden(JC[7])
    );
    
    assign x = my_pixel_index % 96;
    assign y = my_pixel_index / 96;
       
    //reg [3:0] dRE;
    integer dRE;
    
    always @ (posedge clk_25MHz) begin 
        oled_colour <= 16'b11111_111111_11111;
        if (x == 48) begin 
            oled_colour <= 16'b00000_000000_00000;
        end
        
        if (y == 32) begin 
            oled_colour <= 16'b00000_000000_00000;
        end
        
        // divs = 3:1
        if (x == 48 + RE * 3) begin 
            oled_colour <= 16'b11111_000000_00000;
        end
        
        if (y == 32 - IM * 3) begin 
            oled_colour <= 16'b00000_000000_11111;
        end
    
        //for (dRE = 0; dRE != RE; dRE = dRE + 1) begin  -- doesn't work becuase value of RE is unknown when synthesising
        
        // Instead loop through all 16 values of 4 bit dRE with condition
        for (dRE = 0; dRE < 16; dRE = dRE + 1) begin
            if (dRE < RE) begin 
                if (x == 48 + dRE * 3 && y == 32 - dRE * IM * 3 / RE) begin 
                    oled_colour <= 16'b11111_000000_11111;
                end
            end
        end
    end
    
endmodule
