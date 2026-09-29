`include "pwm_ramp.sv"
`include "pwm.sv"
`include "hsv_fade.sv"

// Fade top level module

module top #(
    parameter PWM_INTERVAL = 1200       // CLK frequency is 12MHz, so 1,200 cycles is 100us
)(
    input logic     clk,
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
    // output logic    LED
    );

    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value;
    logic pwm_out;
    // logic led_value = 1'b0;
    logic red;
    logic green;
    logic blue;
    logic cycle_led_states;

    pwm_ramp #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u1 (
        .clk            (clk), 
        .pwm_value      (pwm_value),
        .new_ramp      (cycle_led_states)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u2 (
        .clk            (clk), 
        .pwm_value      (pwm_value), 
        .pwm_out        (pwm_out)
    );

    hsv_fade u3(
        .clk             (clk),
        .increment_state (cycle_led_states),
        .increasing_pwm  (pwm_out),
        .red             (red),
        .green           (green),
        .blue            (blue)
    );



    // assign active-low LEDs 
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;
    // assign RGB_G = 1'b0;
    // assign RGB_R = 1'b1;
    // assign RGB_B = 1'b1;

    // assign RGB_G = (pwm_value == 0)?1'b0:1'b1;
    // assign RGB_G = ~cycle_led_states;
    // assign LED = pwm_out;
    // assign LED = (pwm_out == led_value);
    // always_ff @(posedge cycle_led_states)
        // led_value <= ~led_value;

endmodule
