`timescale 10ns/10ns // 10ns time steps/data recorded every 10ns
`include "top.sv"

module hsv_fade_tb;

    parameter PWM_INTERVAL = 1200;

    logic clk = 0;
    logic RGB_R;
    logic RGB_G;
    logic RGB_B;
    logic[24] clk_cycles = 0; // at note that at 12MHz 12,000,000 cycles is 1s

    top # (
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u0 (
        .clk            (clk),
        .RGB_R          (RGB_R),
        .RGB_G          (RGB_G),
        .RGB_B          (RGB_B)
    );

    initial begin
        $dumpfile("hsv_fade.vcd");
        $dumpvars(0, hsv_fade_tb);
        #60000000
        $finish;
    end

    always begin
        #4 // not 100% accurate
        clk = ~clk;        
    end
    
    always_ff @(posedge clk)
        clk_cycles = clk_cycles + 1; // at 12MHz 12,000 cycles is 1ms

endmodule
