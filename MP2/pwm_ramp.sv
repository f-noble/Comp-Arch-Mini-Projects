// pwm_ramp
// Creates a stepped ramp function with period of 1/6 second and output value ramping from zero to PWM_INTERVAL


module pwm_ramp #(
    parameter INC_INTERVAL = 10000,     // CLK frequency is 12MHz, so 10,000 cycles is 5/6ms
    parameter INCS_PER_RAMP = 200,            // Reset the ramp after 200 increments / steps, which is 1/6s
    parameter PWM_INTERVAL = 1200,          // CLK frequency is 12MHz, so 1,200 cycles is 100us
    parameter INC_VAL = PWM_INTERVAL / INCS_PER_RAMP
)(
    input logic clk, 
    output logic [$clog2(PWM_INTERVAL) - 1:0] pwm_on_time, // # of clock cycles to tell pwm to stay on
    output logic new_ramp // Triggers for a clock cycle every time the ramp resets to zero
);

    // Declare state variables
    logic increment_pwm = 1'b0;
    logic reset_ramp = 1'b0;

    // Declare variables for timing state transitions
    logic [$clog2(INC_INTERVAL) - 1:0] count = 0;
    logic [$clog2(INCS_PER_RAMP) - 1:0] inc_count = 0;


    initial begin
        pwm_on_time = 0;
    end


    // Determines when to step / update pwm_on_time
    always_ff @(posedge clk) begin
        if (count > INC_INTERVAL - 2) begin
            count <= 0;
            increment_pwm <= 1'b1;
        end
        else begin
            count <= count + 1;
            increment_pwm <= 1'b0;
        end
    end


    // Determines when to reset pwm_on_time back to zero
    always_ff @(posedge clk) begin
        if(increment_pwm) begin
            if (inc_count == INCS_PER_RAMP - 1) begin
                inc_count <= 0;
                reset_ramp <= 1'b1;
            end
            else begin
                inc_count <= inc_count + 1;
            end
        end
        else
            reset_ramp <= 1'b0;        
    end


    // Increments pwm_on_time or resets it to zero whenever needed
    always_ff @(posedge clk) begin

        if (reset_ramp)
            pwm_on_time <= 0;
        else
            if (increment_pwm)
                pwm_on_time <= pwm_on_time + INC_VAL;
    end
    
    
    assign new_ramp = reset_ramp;

endmodule
