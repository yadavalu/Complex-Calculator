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
    input [1:0] sw,
    input btnC,btnU,btnL,btnR,btnD,
    output [7:0] JC,
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
    
    argand_plane m_argand_plane(
        .clk_25MHz(clk_25MHz),
        .clk_6p25MHz(clk_6p25MHz),
        .JC(JC),
        .RE(real_1),
        .IM(img_1)
    );
    
    
    input_display m_input_display(
        .basys_clock(clk),
        .clk_2Hz(clk_2Hz),
        .clk_500Hz(clk_500Hz),
        .led(led),
        .sw(sw),
        .btnC(btnC),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .seg(seg),
        .an(an),
        .real_1(real_1),
        .img_1(img_1)
    );

endmodule