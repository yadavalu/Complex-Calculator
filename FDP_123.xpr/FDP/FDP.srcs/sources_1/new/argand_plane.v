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
       
    // -------------------------------------------------------------------------
    // Coordinate Math & Scaling (Combinational)
    // -------------------------------------------------------------------------
    
    // 1. Sign Extension
    wire signed [31:0] s_x  = x;
    wire signed [31:0] s_y  = y;
    wire signed [31:0] s_RE = {{12{RE[19]}}, RE}; 
    wire signed [31:0] s_IM = {{12{IM[19]}}, IM};

    // 2. 180-Degree Screen Rotation
    wire signed [31:0] rx = 48 - s_x;
    wire signed [31:0] ry = s_y - 32; 
    
    // 3. Absolute values to find the maximum coordinate bounds
    wire signed [31:0] abs_RE = (s_RE < 0) ? -s_RE : s_RE;
    wire signed [31:0] abs_IM = (s_IM < 0) ? -s_IM : s_IM;
    wire signed [31:0] max_coord = (abs_RE > abs_IM) ? abs_RE : abs_IM;

    // -------------------------------------------------------------------------
    // AUTO-ZOOM LOGIC
    // -------------------------------------------------------------------------
    // We want the maximum coordinate to sit around 32 pixels away from the origin.
    // SCALE = max_coord / 32. In hardware, dividing by 32 is a Right Shift by 5.
    wire signed [31:0] calc_scale = max_coord >> 5;
    ++++
    // Ensure scale never drops to 0 (which would collapse the math to a black hole)
    wire signed [31:0] dynamic_scale = (calc_scale == 0) ? 1 : calc_scale;
    
    localparam signed [31:0] FIXED_SCALE = 625;
    
    // Multiplexer to choose between fixed scale and dynamic scale based on input switch
    wire signed [31:0] SCALE = auto_zoom ? dynamic_scale : FIXED_SCALE;

    // -------------------------------------------------------------------------
    
    // Apply the chosen scale to the pixel coordinates
    wire signed [31:0] rx_scaled = rx * SCALE;
    wire signed [31:0] ry_scaled = ry * SCALE;

    // 4. Cross product
    wire signed [31:0] cross = (rx_scaled * s_IM) - (ry_scaled * s_RE);
    wire signed [31:0] abs_cross = (cross < 0) ? -cross : cross;

    // 5. Fully Adaptive Threshold
    // By tying the threshold directly to the active SCALE, the line thickness 
    // will remain perfectly consistent (~1-2 pixels) regardless of how far in or out we zoom.
    wire signed [31:0] thresh = SCALE * max_coord; 

    // 6. Bounding box to stop the line at the endpoint
    wire in_bound_x = (s_RE >= 0) ? (rx_scaled >= -SCALE && rx_scaled <= s_RE + SCALE) : 
                                    (rx_scaled <= SCALE && rx_scaled >= s_RE - SCALE);
    wire in_bound_y = (s_IM >= 0) ? (ry_scaled >= -SCALE && ry_scaled <= s_IM + SCALE) : 
                                    (ry_scaled <= SCALE && ry_scaled >= s_IM - SCALE);

    // 7. Render triggers
    wire is_line = in_bound_x && in_bound_y && (abs_cross <= thresh);
    
    // 8. Find the exact mathematical endpoint to draw a clean dot marker
    wire is_re_end = (rx_scaled >= s_RE - SCALE) && (rx_scaled <= s_RE + SCALE);
    wire is_im_end = (ry_scaled >= s_IM - SCALE) && (ry_scaled <= s_IM + SCALE);
    wire is_endpoint = is_re_end && is_im_end;

    // -------------------------------------------------------------------------
    // Pixel Rendering (Sequential)
    // -------------------------------------------------------------------------

    always @ (posedge clk_25MHz) begin 
        oled_colour <= 16'b11111_111111_11111; // Default White
        
        // Draw Origin Axes
        if (rx == 0 || ry == 0) begin 
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
