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
    output [7:0] JC
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
    
    argand_plane m_argand_plane(
        .clk_25MHz(clk_25MHz),
        .clk_6p25MHz(clk_6p25MHz),
        .JC(JC),
        .RE(4'd7),
        .IM(4'd3)
    );

endmodule