`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2026 22:11:41
// Design Name: 
// Module Name: input_display
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


`define zero   8'b11000000  
`define one    8'b11111001  
`define two    8'b10100100  
`define three  8'b10110000  
`define four   8'b10011001  
`define five   8'b10010010  
`define six    8'b10000010  
`define seven  8'b11111000  
`define eight  8'b10000000  
`define nine   8'b10010000  

module number_selector(input basys_clock, input [3:0] count, output reg [7:0]  display_num );

    always @ (posedge basys_clock) begin
        case(count)
        0:   begin
                display_num <= `zero;
                end
        1: begin                
                display_num <= `one;
                end
        2: begin               
                display_num <= `two;
                end
        3: begin                
               display_num <= `three;
                end
        4: begin               
               display_num <= `four;
                end
        5: begin               
               display_num <= `five;
                end 
        6: begin                              
               display_num <= `six;
                end
        7: begin                                             
               display_num <= `seven;
                end
        8: begin                                                       
               display_num <= `eight;
                end
        9: begin                                                                               
               display_num <= `nine;
                end                                                                                                                                                               
        default: begin
                display_num <= `zero;
                end
    endcase
    end
    

endmodule
module input_display(
    input basys_clock,
    input clk_2Hz,
    input clk_500Hz,
    output [1:0] led,
    input [1:0] sw,
    input btnC,btnU,btnL,btnR,btnD,
    output reg [7:0] seg,
    output reg [3:0] an,
    output reg [6:0] real_1, img_1//, real_2, img_2

    );
    reg [7:0]  real_2, img_2;// to be put as outputs when integrating
//    wire clk_500Hz,clk_2Hz;
    reg btnU_delay, btnD_delay,btnL_delay,btnR_delay,btnC_delay;

    wire [7:0] d1 ,d2 ,d3 ,d4;
    reg [1:0] display_count = 2'd0; // to display on 7 segment
    reg [1:0] anode_count = 2'd0; // to choose anode position
    wire [3:0] n1 ,n2 ,n3 ,n4;
    reg [3:0] n1_count = 0,n2_count = 0,n3_count = 0,n4_count = 0; // to choose number to display operand 1
    reg [3:0] n5_count = 0,n6_count = 0,n7_count = 0,n8_count = 0; // to choose number to display operand 2
//    clock f_500Hz(basys_clock,99999,clk_500Hz);
//    clock f_2Hz(basys_clock,24999999,clk_2Hz);
    number_selector digit1(basys_clock,n1,d1);
    number_selector digit2(basys_clock,n2,d2);
    number_selector digit3(basys_clock,n3,d3);
    number_selector digit4(basys_clock,n4,d4);
    // MUX selction for output
    assign n1 = (sw[1]) ? n5_count : n1_count;
    assign n2 = (sw[1]) ? n6_count : n2_count;
    assign n3 = (sw[1]) ? n7_count : n3_count;
    assign n4 = (sw[1]) ? n8_count : n4_count;
    assign led[0] = (sw[0]) ? 1 : 0;
    assign led[1] = (sw[1]) ? 1 : 0;
    
    //display clock
    always @ (posedge clk_500Hz) begin
        if (display_count < 2'd3)
           display_count <= display_count + 2'd1;
        else
            display_count <= 2'd0;
    end
 
    //button press and display
    always @(posedge clk_500Hz) begin
    btnU_delay <= btnU;
    btnD_delay <= btnD;
    btnL_delay <= btnL;
    btnR_delay <= btnR;
    btnC_delay <= btnC;
        if (btnU == 1 && btnU_delay == 0) begin // increment
        case(anode_count)
                    0:  if (sw[1]==0) begin
                            if (n1_count < 9) n1_count <= n1_count + 1;
                        end 
                        else begin
                            if (n5_count < 9) n5_count <= n5_count + 1;
                        end
                    1: if (sw[1]==0) begin
                            if (n2_count < 9) n2_count <= n2_count + 1;
                        end 
                        else begin
                            if (n6_count < 9) n6_count <= n6_count + 1;
                        end
                    2: if (sw[1]==0) begin
                            if (n3_count < 9) n3_count <= n3_count + 1;
                        end 
                        else begin
                            if (n7_count < 9) n7_count <= n7_count + 1;
                        end
                    3: if (sw[1]==0) begin
                            if (n4_count < 9) n4_count <= n4_count + 1;
                        end 
                        else begin
                            if (n8_count < 9) n8_count <= n8_count + 1;
                        end

                    default: begin

                             end
                endcase

        end
        else if (btnD == 1 && btnD_delay == 0) begin // decrement
         case(anode_count)
                0:   if (sw[1]==0) begin
                         if (n1_count > 0) n1_count <= n1_count - 1;
                     end 
                     else begin
                         if (n5_count > 0) n5_count <= n5_count - 1;
                     end
                1: if (sw[1]==0) begin
                        if (n2_count > 0) n2_count <= n2_count - 1;
                    end 
                    else begin
                        if (n6_count > 0) n6_count <= n6_count - 1;
                    end
                2: if (sw[1]==0) begin
                       if (n3_count > 0) n3_count <= n3_count - 1;
                   end 
                   else begin
                       if (n7_count > 0) n7_count <= n7_count - 1;
                   end
                3: if (sw[1]==0) begin
                        if (n4_count > 0) n4_count <= n4_count - 1;
                    end 
                    else begin
                        if (n8_count > 0) n8_count <= n8_count - 1;
                    end
                
                default: begin

                         end
            endcase
            end
            
        else if (btnR == 1 && btnR_delay == 0) begin // select rgiht
            if (anode_count > 2'd0)
                anode_count <= anode_count - 1; 
            end
            
        else if (btnL == 1 && btnL_delay == 0) begin // select left
            if (anode_count < 2'd3)
                anode_count <= anode_count + 1;                      
        end
        
        else if (btnC == 1 && btnC_delay == 0) begin // output selection
           real_1 <=  n4_count*10 + n3_count;    
           img_1 <=  n2_count*10 + n1_count; 
           real_2 <=  n8_count*10 + n7_count; 
           img_2 <=  n7_count*10 + n5_count;                 
        end       
        
        if (sw[0]) begin
            n1_count <= 0;n2_count <= 0;n3_count <= 0;n4_count <= 0; 
            n5_count <= 0;n6_count <= 0;n7_count <= 0;n8_count <= 0;
            real_1 <=  0;img_1 <=  0;real_2 <=  0;img_2 <=  0;                           
        end
        
        // display on 7 segment
        case(display_count)
            0:   begin
                    an <= (anode_count == 0) ? ((clk_2Hz) ? 4'b1110 : 4'b1111) : 4'b1110;      
                    seg <= d1;
                    end
            1: begin 
                    an <= (anode_count == 1) ?((clk_2Hz) ? 4'b1101 : 4'b1111):4'b1101;
                    seg <= d2;
                    end
            2: begin   
                    an <= (anode_count == 2) ?((clk_2Hz) ? 4'b1011 : 4'b1111):4'b1011;
                    seg <= d3;
                    seg[7] <=0;
                    end
            3: begin
                    an <= (anode_count == 3) ?((clk_2Hz) ? 4'b0111 : 4'b1111):4'b0111;             
                    seg <= d4;
                    end
            
            default: begin
                     an <=  4'b1111;
                     end
        endcase
    end
    
    
    
endmodule
