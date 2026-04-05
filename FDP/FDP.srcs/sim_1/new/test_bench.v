module test_bench();
    reg clk;
    reg [3:0] sw;
    
    // 99 needs 7 bits unsigned, but to use "signed" math for 99, 
    // you need 8 bits [7:0] so the top bit isn't used as a minus sign.
    reg signed [7:0] real_1, img_1, real_2, img_2; 

    // MUST match the 16-bit output of the module
    wire signed [19:0] real_num, img_num; 

    // Instantiate (no changes needed here, but ensure widths match)
    Calculate uut (
        .clk(clk),
        .sw(sw),
        .real_1(real_1[6:0]), // passing the 7 bits
        .img_1(img_1[6:0]),
        .real_2(real_2[6:0]),
        .img_2(img_2[6:0]),
        .real_num(real_num),
        .img_num(img_num)
   );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        
        // Give it a moment to reset
        #10;

        // -------- TEST 1: ADD (Expect 100.0) --------
        real_1 = 2; img_1 = 3;
        real_2 = 1; img_2 = 2;

        sw = 4'b0001; 
        @(posedge clk); // Wait for clock to process

        // -------- TEST 2: SUB (Expect 0.0) --------
        sw = 4'b0010;
        @(posedge clk);

        // -------- TEST 3: MULT (Expect 2492.0 + 300.0j) --------
        sw = 4'b0100;
        @(posedge clk);

        // -------- TEST 4: DIV (Expect 1.6 + 0.2j) --------

        sw = 4'b1000;
        @(posedge clk);
        @(posedge clk); // Division can be slow, give it an extra cycle
        sw = 4'b0001; 
        @(posedge clk); // Wait for clock to process

        // -------- TEST 2: SUB (Expect 0.0) --------
        sw = 4'b0010;
        @(posedge clk);

        // -------- TEST 3: MULT (Expect 2492.0 + 300.0j) --------
        sw = 4'b0100;
        @(posedge clk);
        #20;
        $stop;
    end
    
    // Display the results
    always @(posedge clk) begin
        $display("SW: %b | REAL = %d (%f), IMAG = %d (%f)",
            sw, real_num, real_num / 16.0,
            img_num, img_num / 16.0);
    end
endmodule