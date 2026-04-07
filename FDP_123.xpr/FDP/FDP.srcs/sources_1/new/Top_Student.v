`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: 
//  STUDENT B NAME:
//  STUDENT C NAME: 
//  STUDENT D NAME:  
//
//////////////////////////////////////////////////////////////////////////////////


module Top_Student (
    input clk,
    input [1:0] sw_i,
    input [3:0] sw,
    input btnC,btnU,btnL,btnR,btnD,
    output [7:0] JA,
    output [7:0] JB,
    output [1:0] led,
    output [7:0] seg,
    output [3:0] an
    );
            
    wire clk_25MHz;
    clock clk_25MHz_inst (
        .basys_clock(clk), .m(32'd1),  // m = f_c/(2f_d) - 1
        .my_clock(clk_25MHz)
    );

    wire clk_6p25MHz;
    clock clk_6p25MHz_inst (
        .basys_clock(clk), .m(32'd7),  // m = f_c/(2f_d) - 1
        .my_clock(clk_6p25MHz)
    );
    
    wire clk_500Hz;
        clock clk_500Hz_inst (
            .basys_clock(clk), .m(99999),  // m = f_c/(2f_d) - 1
            .my_clock(clk_500Hz)
        );
        
    wire clk_2Hz;
        clock clk_2Hz_inst (
            .basys_clock(clk), .m(24999999),  // m = f_c/(2f_d) - 1
            .my_clock(clk_2Hz)
        );
    
     wire [6:0] real_1, img_1, real_2, img_2;
     wire [19:0] output1,output2;
     wire error;
    
    argand_plane m_argand_plane(
        .clk_25MHz(clk_25MHz),
        .clk_6p25MHz(clk_6p25MHz),
        .JA(JA),
        .RE(output1),
        .IM(output2)
    );
    
    
    input_display m_input_display(
        .basys_clock(clk),
        .clk_500Hz(clk_500Hz),
        .clk_2Hz(clk_2Hz),
        .led(led),
        .sw(sw_i),
        .btnC(btnC),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .seg(seg),
        .an(an),
        .real_1(real_1),
        .img_1(img_1),
        .real_2(real_2),
        .img_2(img_2)
    );
    
    Calculate m_Calculate(
        .clk(clk), 
        .sw(sw),
        .real_1(real_1),
        .img_1(img_1),
        .real_2(real_2),
        .img_2(img_2),  // 7-bit unsigned inputs
        .real_num(output1),          // Increased to 16-bit to prevent overflow
        .img_num(output2),
        .error(error)
    );
    
    Display m_Display(
        .clk(clk_6p25MHz),
        .real_num(output1),
        .img_num(output2),
        .error(error),
        .JB(JB)
    );
endmodule