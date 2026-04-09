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
    input [23:0] RE,
    input [23:0] IM,
    input auto_zoom,
    output [7:0] JA
    );
    
    wire my_frame_begin, my_sending_pixel, my_sample_pixel;
    wire [12:0] my_pixel_index;
    reg [15:0] oled_colour = 16'b11111_111111_11111;
    wire [6:0] x;
    wire [5:0] y;
    
    Oled_Display oled(
        .clk(clk_6p25MHz), .reset(0), .frame_begin(my_frame_begin), .sending_pixels(my_sending_pixel),
        .sample_pixel(my_sample_pixel), .pixel_index(my_pixel_index), .pixel_data(oled_colour), .cs(JA[0]), .sdin(JA[1]), .sclk(JA[3]), .d_cn(JA[4]), .resn(JA[5]), .vccen(JA[6]),
        .pmoden(JA[7])
    );
    
    assign x = my_pixel_index % 96;
    assign y = my_pixel_index / 96;
       
    // Signed bit extensions
    wire signed [31:0] s_x  = x;
    wire signed [31:0] s_y  = y;
    wire signed [31:0] s_RE = {{8{RE[23]}}, RE}; 
    wire signed [31:0] s_IM = {{8{IM[23]}}, IM};

    // Flipped screen rotation by 180°
    wire signed [31:0] rx = 48 - s_x;
    wire signed [31:0] ry = s_y - 32; 
    
    // Maximum coordinate bounds
    wire signed [31:0] abs_RE = (s_RE < 0) ? -s_RE : s_RE;
    wire signed [31:0] abs_IM = (s_IM < 0) ? -s_IM : s_IM;
    wire signed [31:0] max_coord = (abs_RE > abs_IM) ? abs_RE : abs_IM;

    // maximum coordinate sits 32 pixels away from the origin.
    wire signed [31:0] calc_scale = max_coord >> 5;  // divide by 32
    wire signed [31:0] dynamic_scale = (calc_scale == 0) ? 1 : calc_scale;
    
    localparam signed [31:0] FIXED_SCALE = 625;
    
    // Multiplex between fixed scale and dynamic scale based on input switch
    wire signed [31:0] SCALE = auto_zoom ? dynamic_scale : FIXED_SCALE;

    
    // Apply the chosen scale to the pixel coordinates
    wire signed [31:0] rx_scaled = rx * SCALE;
    wire signed [31:0] ry_scaled = ry * SCALE;


    wire signed [47:0] cross = (rx_scaled * s_IM) - (ry_scaled * s_RE);
    wire signed [47:0] abs_cross = (cross < 0) ? -cross : cross;

    // Maintain line thickness using threshold
    wire signed [47:0] thresh = SCALE * max_coord; 

    // Constrain the line at the endpoint
    wire in_bound_x = (s_RE >= 0) ? (rx_scaled >= -SCALE && rx_scaled <= s_RE + SCALE) : 
                                    (rx_scaled <= SCALE && rx_scaled >= s_RE - SCALE);
    wire in_bound_y = (s_IM >= 0) ? (ry_scaled >= -SCALE && ry_scaled <= s_IM + SCALE) : 
                                    (ry_scaled <= SCALE && ry_scaled >= s_IM - SCALE);

    wire is_line = in_bound_x && in_bound_y && (abs_cross <= thresh);
    wire is_re_end = (rx_scaled >= s_RE - SCALE) && (rx_scaled <= s_RE + SCALE);
    wire is_im_end = (ry_scaled >= s_IM - SCALE) && (ry_scaled <= s_IM + SCALE);
    wire is_endpoint = is_re_end && is_im_end;

    always @ (posedge clk_25MHz) begin 
        oled_colour <= 16'b11111_111111_11111; // Default White
        
        if (rx == 0 || ry == 0) begin 
            oled_colour <= 16'b00000_000000_00000; // Black
        end
            
        if (is_line) begin
            oled_colour <= 16'b11111_000000_11111; // Magenta
        end
        
        if (is_endpoint) begin 
            oled_colour <= 16'b11111_111111_00000; // Yellow
        end
    end

endmodule
