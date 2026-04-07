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
    input [19:0] RE,
    input [19:0] IM,
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
       
    // -------------------------------------------------------------------------
    // Coordinate Math & Scaling (Combinational)
    // -------------------------------------------------------------------------
    
    // 1. BULLETPROOF SIGN EXTENSION
    wire signed [31:0] s_x  = x;
    wire signed [31:0] s_y  = y;
    wire signed [31:0] s_RE = {{12{RE[19]}}, RE}; 
    wire signed [31:0] s_IM = {{12{IM[19]}}, IM};

    // 2. 180-Degree Screen Rotation around origin (48, 32)
    // Hardware (0,0) is now visually Bottom-Right.
    // Hardware (0,63) is now visually Top-Right.
    wire signed [31:0] rx = 48 - s_x;
    wire signed [31:0] ry = s_y - 32; // FIXED: Y-axis inversion corrected
    
    // 3. SCALE UP screen coordinates.
    localparam signed [31:0] SCALE = 625;
    wire signed [31:0] rx_scaled = rx * SCALE;
    wire signed [31:0] ry_scaled = ry * SCALE;

    // 4. Cross product using the scaled coordinates
    wire signed [31:0] cross = (rx_scaled * s_IM) - (ry_scaled * s_RE);
    wire signed [31:0] abs_cross = (cross < 0) ? -cross : cross;

    // 5. Dynamic threshold for uniform line thickness
    wire signed [31:0] abs_RE = (s_RE < 0) ? -s_RE : s_RE;
    wire signed [31:0] abs_IM = (s_IM < 0) ? -s_IM : s_IM;
    wire signed [31:0] max_coord = (abs_RE > abs_IM) ? abs_RE : abs_IM;
    wire signed [31:0] thresh = 400 * max_coord; 

    // 6. Bounding box to stop the line at the endpoint
    wire in_bound_x = (s_RE >= 0) ? (rx_scaled >= -SCALE && rx_scaled <= s_RE + SCALE) : 
                                    (rx_scaled <= SCALE && rx_scaled >= s_RE - SCALE);
    wire in_bound_y = (s_IM >= 0) ? (ry_scaled >= -SCALE && ry_scaled <= s_IM + SCALE) : 
                                    (ry_scaled <= SCALE && ry_scaled >= s_IM - SCALE);

    // 7. Render triggers
    wire is_line = in_bound_x && in_bound_y && (abs_cross <= thresh);
    
    // 8. Find the exact mathematical endpoint to draw a clean dot marker
    wire is_re_end = (rx_scaled >= s_RE - (SCALE/2)) && (rx_scaled <= s_RE + (SCALE/2));
    wire is_im_end = (ry_scaled >= s_IM - (SCALE/2)) && (ry_scaled <= s_IM + (SCALE/2));
    wire is_endpoint = is_re_end && is_im_end;

    // -------------------------------------------------------------------------
    // Pixel Rendering (Sequential)
    // -------------------------------------------------------------------------

    always @ (posedge clk_25MHz) begin 
        oled_colour <= 16'b11111_111111_11111; // Default White
        
        // Draw Origin Axes
        if (x == 48 || y == 32) begin 
            oled_colour <= 16'b00000_000000_00000; // Black
        end
            
        // Draw the Solid Diagonal Vector
        if (is_line) begin
            oled_colour <= 16'b11111_000000_11111; // Magenta
        end
        
        // Draw a clean Endpoint Dot on top of the line
        if (is_endpoint) begin 
            oled_colour <= 16'b11111_111111_00000; // Yellow
        end
    end

endmodule
