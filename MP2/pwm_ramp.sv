// pwm_ramp
// Creates pwm signals that step from 0-100% duty cycle every interval

module pwm_ramp #(
    parameter INC_DEC_INTERVAL = 100000,     // CLK frequency is 12MHz, so 10,000 cycles is 5/6ms
    parameter INC_DEC_MAX = 200,            // Transition to next state after 200 increments / decrements, which is 1/6s
    parameter PWM_INTERVAL = 1200,          // CLK frequency is 12MHz, so 1,200 cycles is 100us
    parameter INC_DEC_VAL = PWM_INTERVAL / INC_DEC_MAX
)(
    input logic clk, 
    output logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value,
    output logic new_ramp
);

    // Define state variable values
    localparam PWM_INC = 1'b0;
    localparam PWM_DEC = 1'b1;

    // Declare state variables
    // logic current_state = PWM_INC;
    // logic next_state;

    // Declare variables for timing state transitions
    logic [$clog2(INC_DEC_INTERVAL) - 1:0] count = 0;
    logic [$clog2(INC_DEC_MAX) - 1:0] inc_dec_count = 0;
    logic time_to_inc_dec = 1'b0;
    logic time_to_transition = 1'b0;

    initial begin
        pwm_value = 0;
    end

    // Register the next state of the FSM
    always_ff @(posedge time_to_transition)
        pwm_value <= 0;
        // current_state <= next_state;

    // Compute the next state of the FSM
    // always_comb begin
    //     next_state = 1'bx;
    //     case (current_state)
    //         PWM_INC:
    //             next_state = PWM_DEC;
    //         PWM_DEC:
    //             next_state = PWM_INC;
    //     endcase
    // end

    // Implement counter for incrementing / decrementing PWM value
    always_ff @(posedge clk) begin
        if (count == INC_DEC_INTERVAL - 1) begin
            count <= 0;
            time_to_inc_dec <= 1'b1;
        end
        else begin
            count <= count + 1;
            time_to_inc_dec <= 1'b0;
        end
    end

    // Increment / Decrement PWM value as appropriate given current state
    always_ff @(posedge time_to_inc_dec) begin
        pwm_value <= pwm_value + INC_DEC_VAL;
        // case (current_state)
            // PWM_INC:
                // pwm_value <= pwm_value + INC_DEC_VAL;
            // PWM_DEC:
                // pwm_value <= pwm_value - INC_DEC_VAL;
        // endcase
    end

    // Implement counter for restarting the ramp
    always_ff @(posedge time_to_inc_dec) begin
        if (inc_dec_count == INC_DEC_MAX - 1) begin
            inc_dec_count <= 0;
            time_to_transition <= 1'b1;
        end
        else begin
            inc_dec_count <= inc_dec_count + 1;
            time_to_transition <= 1'b0;
        end
    end

    assign new_ramp = time_to_transition;

endmodule
