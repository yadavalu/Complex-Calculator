`timescale 1ns / 1ps

module Display(
    input clk,
    input signed [23:0] real_num, 
    input signed [23:0] img_num,  
    input error,
    output [7:0] JB
    );
    
   // abs value
    wire [23:0] real_abs_full = (real_num[23]) ? -real_num : real_num;
    wire [23:0] img_abs_full  = (img_num[23])  ? -img_num  : img_num;
    
    // integer and fraction extraction
    wire [15:0] real_abs = real_abs_full[23:8];
    wire [15:0] img_abs  = img_abs_full[23:8];
    
    wire [7:0] real_frac_bits = real_abs_full[7:0];
    wire [7:0] img_frac_bits  = img_abs_full[7:0];
    
    wire [15:0] real_frac_mult = real_frac_bits * 7'd100;
    wire [15:0] img_frac_mult  = img_frac_bits  * 7'd100;
    
    wire [7:0] real_frac_dec = real_frac_mult >> 8;
    wire [7:0] img_frac_dec  = img_frac_mult >> 8;
    
    // sign
    wire real_neg = real_num[23];
    wire img_neg  = img_num[23];

    // digit extraction
    wire [3:0] r_tten = (real_abs / 10000)% 10; 
    wire [3:0] r_thou = (real_abs / 1000) % 10;
    wire [3:0] r_hund = (real_abs / 100)  % 10;
    wire [3:0] r_tens = (real_abs / 10)   % 10;
    wire [3:0] r_ones =  real_abs         % 10;

    wire [3:0] i_tten = (img_abs / 10000) % 10;
    wire [3:0] i_thou = (img_abs / 1000) % 10;
    wire [3:0] i_hund = (img_abs / 100)  % 10;
    wire [3:0] i_tens = (img_abs / 10)   % 10;
    wire [3:0] i_ones =  img_abs         % 10;

    wire [3:0] r_frac_tens = (real_frac_dec / 10) % 10;
    wire [3:0] r_frac_ones = real_frac_dec % 10;
    wire [3:0] i_frac_tens = (img_frac_dec / 10) % 10;
    wire [3:0] i_frac_ones = img_frac_dec % 10;

    // OLED
    wire [12:0] pixel_index;
    wire send_pix;
    wire samp_pix = 1'b1;
    reg [15:0] oled_colour;

    wire [6:0] x = pixel_index % 96;
    wire [5:0] y = pixel_index / 96;

    Oled_Display display (
        .clk(clk),
        .reset(1'b0),
        .frame_begin(),
        .sending_pixels(send_pix),
        .sample_pixel(samp_pix),
        .pixel_index(pixel_index),
        .pixel_data(oled_colour),
        .cs(JB[0]),   .sdin(JB[1]),
        .sclk(JB[3]), .d_cn(JB[4]),
        .resn(JB[5]), .vccen(JB[6]),
        .pmoden(JB[7])
    );

    
    localparam CHAR_H = 20;
    localparam CHAR_W = 9;
    localparam LINE_T = 2;

    localparam X_SIGN  = 0;
    localparam X_D4   = 10;  
    localparam X_D3    = 20;
    localparam X_D2    = 30;
    localparam X_D1    = 40;
    localparam X_D0    = 50;
    localparam X_DOT   = 60;
    localparam X_F1    = 63;
    localparam X_F0    = 73;
    localparam X_I     = 83;

    localparam Y_REAL  = 3;
    localparam Y_IMAG  = 36;

    function [6:0] char_to_seg;
        input [7:0] char; 
        case(char)
            "E": char_to_seg = 7'b1111001; 
            "R": char_to_seg = 7'b0011000;
            "O": char_to_seg = 7'b1110111; 
            
            0: char_to_seg = 7'b1110111; 1: char_to_seg = 7'b0000110;
            2: char_to_seg = 7'b1011101; 3: char_to_seg = 7'b1001111;
            4: char_to_seg = 7'b0101110; 5: char_to_seg = 7'b1101011;
            6: char_to_seg = 7'b1111011; 7: char_to_seg = 7'b1000110;
            8: char_to_seg = 7'b1111111; 9: char_to_seg = 7'b1101111;
            default: char_to_seg = 7'b0000000;
        endcase
    endfunction

    function draw_digit;
        input [6:0] px; input [5:0] py; input [6:0] X; input [5:0] Y; input [6:0] segs;
        draw_digit =
            (segs[6] && px>=X && px<X+CHAR_W && py>=Y && py<Y+LINE_T) |
            (segs[3] && px>=X && px<X+CHAR_W && py>=Y+CHAR_H/2-LINE_T/2 && py<Y+CHAR_H/2+LINE_T/2) |
            (segs[0] && px>=X && px<X+CHAR_W && py>=Y+CHAR_H-LINE_T && py<Y+CHAR_H) |
            (segs[5] && px>=X && px<X+LINE_T && py>=Y && py<Y+CHAR_H/2) |
            (segs[4] && px>=X && px<X+LINE_T && py>=Y+CHAR_H/2 && py<Y+CHAR_H) |
            (segs[2] && px>=X+CHAR_W-LINE_T && px<X+CHAR_W && py>=Y && py<Y+CHAR_H/2) |
            (segs[1] && px>=X+CHAR_W-LINE_T && px<X+CHAR_W && py>=Y+CHAR_H/2 && py<Y+CHAR_H);
    endfunction

    function draw_minus; input [6:0] px; input [5:0] py; input [6:0] X; input [5:0] Y; 
        draw_minus = (px>=X)&&(px<X+7)&&(py>=Y+CHAR_H/2-LINE_T/2)&&(py<Y+CHAR_H/2+LINE_T/2);
    endfunction

    function draw_plus; input [6:0] px; input [5:0] py; input [6:0] X; input [5:0] Y; 
        draw_plus = ((px>=X)&&(px<X+7)&&(py>=Y+CHAR_H/2-LINE_T/2)&&(py<Y+CHAR_H/2+LINE_T/2)) |
                    ((px>=X+3)&&(px<X+5)&&(py>=Y+2)&&(py<Y+CHAR_H-2));
    endfunction

    function draw_dot; input [6:0] px; input [5:0] py; input [6:0] X; input [5:0] Y; 
        draw_dot = (px>=X)&&(px<X+2)&&(py>=Y+CHAR_H-LINE_T)&&(py<Y+CHAR_H);
    endfunction

    function draw_i; input [6:0] px; input [5:0] py; input [6:0] X; input [5:0] Y; 
        draw_i = ((px>=X+1)&&(px<X+4)&&(py>=Y)&&(py<Y+LINE_T)) |
                 ((px>=X+1)&&(px<X+4)&&(py>=Y+4)&&(py<Y+CHAR_H));
    endfunction

    // pixels
    reg draw_real_row, draw_imag_row, draw_error_msg;

    always @(*) begin
        
        draw_real_row =
            (real_neg ? draw_minus(x,y,X_SIGN,Y_REAL) : draw_plus(x,y,X_SIGN,Y_REAL)) |
            draw_digit(x,y,X_D4,Y_REAL,char_to_seg(r_tten)) |                
            draw_digit(x,y,X_D3,Y_REAL,char_to_seg(r_thou)) |
            draw_digit(x,y,X_D2,Y_REAL,char_to_seg(r_hund)) |
            draw_digit(x,y,X_D1,Y_REAL,char_to_seg(r_tens)) |
            draw_digit(x,y,X_D0,Y_REAL,char_to_seg(r_ones)) |
            draw_dot(x,y,X_DOT,Y_REAL) |
            draw_digit(x,y,X_F1,Y_REAL,char_to_seg(r_frac_tens)) |
            draw_digit(x,y,X_F0,Y_REAL,char_to_seg(r_frac_ones));

        draw_imag_row =
            (img_neg ? draw_minus(x,y,X_SIGN,Y_IMAG) : draw_plus(x,y,X_SIGN,Y_IMAG)) |
            draw_digit(x,y,X_D4,Y_IMAG,char_to_seg(i_tten)) |
            draw_digit(x,y,X_D3,Y_IMAG,char_to_seg(i_thou)) |
            draw_digit(x,y,X_D2,Y_IMAG,char_to_seg(i_hund)) |
            draw_digit(x,y,X_D1,Y_IMAG,char_to_seg(i_tens)) |
            draw_digit(x,y,X_D0,Y_IMAG,char_to_seg(i_ones)) |
            draw_dot(x,y,X_DOT,Y_IMAG) |
            draw_digit(x,y,X_F1,Y_IMAG,char_to_seg(i_frac_tens)) |
            draw_digit(x,y,X_F0,Y_IMAG,char_to_seg(i_frac_ones)) |
            draw_i(x,y,X_I,Y_IMAG);

        draw_error_msg = 
            draw_digit(x,y, 20, 25, char_to_seg("E")) | 
            draw_digit(x,y, 30, 25, char_to_seg("R")) | 
            draw_digit(x,y, 40, 25, char_to_seg("R")) | 
            draw_digit(x,y, 50, 25, char_to_seg("O")) | 
            draw_digit(x,y, 60, 25, char_to_seg("R"));
    end

    always @(posedge clk) begin
        if (error) begin
            if (draw_error_msg) oled_colour <= 16'b11111_000000_00000; 
            else                oled_colour <= 16'b00000_000000_00000;
        end else begin
            if      (draw_real_row) oled_colour <= 16'b11111_111111_00000; 
            else if (draw_imag_row) oled_colour <= 16'b00000_111111_11111; 
            else                    oled_colour <= 16'b00000_000000_00000; 
        end
    end

endmodule
