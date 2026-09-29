`timescale 10ns/10ns // 10ns time steps/data recorded every 10ns
`include "top.sv"


// used for testing why this specific function was not working
module pwm_ramp_only_tb;

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
        // .RGB_R          (RGB_R),
        .RGB_G          (RGB_G)//,
        // .RGB_B          (RGB_B)
    );

    initial begin
        $dumpfile("pwm_ramp_only.vcd");
        $dumpvars(0, pwm_ramp_only_tb);
        #60000000
        $finish;
    end

    always begin
        #4 // not 100% accurate
        clk = ~clk;        
    end
    
    always_ff @(posedge clk) // figure out exact times
        clk_cycles = clk_cycles + 1; // at 12MHz 12,000 cycles is 1ms

endmodule
