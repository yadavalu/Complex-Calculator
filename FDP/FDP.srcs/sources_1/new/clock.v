`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.03.2026 10:16:37
// Design Name: 
// Module Name: clock
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


module clock(
    input basys_clock, [31:0] m,  // m = f_c/(2f_d) - 1
    output reg my_clock = 0
    );

    reg [31:0] count = 0;
    always @ (posedge basys_clock) begin
        count <= count == m ? 0 : count + 1;
        my_clock <= count == 0 ? ~my_clock : my_clock;
    end

endmodule
