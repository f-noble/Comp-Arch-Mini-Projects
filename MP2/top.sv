`include "pwm_ramp.sv"
`include "pwm.sv"
`include "hsv_fade.sv"

// HSV Fade project top level module
// Fades an RGB led around the 6 colors on the hsv color wheel once every second

module top #(
    parameter PWM_INTERVAL = 1200       // CLK frequency is 12MHz, so 1,200 cycles is 100us
)(
    input logic     clk,
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
    );

    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_on_time;
    logic pwm_out;
    logic red;
    logic green;
    logic blue;
    logic cycle_led_states;

    // Generates a ramp function with frequency 1/6 second
    pwm_ramp #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u1 (
        .clk            (clk), 
        .pwm_on_time    (pwm_on_time),
        .new_ramp       (cycle_led_states)
    );

    // Generates a PWM signal with duty cycle determined by the value of the ramp from above
    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u2 (
        .clk            (clk), 
        .pwm_on_time    (pwm_on_time), 
        .pwm_out        (pwm_out)
    );

    // State machine that determines which RGB colors should be on / off / brightening / fading and assigns a fading PWM or constant value to them
    hsv_fade u3(
        .clk             (clk),
        .increment_state (cycle_led_states),
        .increasing_pwm  (pwm_out),
        .red             (red),
        .green           (green),
        .blue            (blue)
    );


    // Set values of output pins for active-low LEDs 
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;

endmodule
