// Fades the RGB LEDs on the board between 6 colors around the HSV color wheel every second, using a PWM signal tied to a ramp to fade the colors on or off

module hsv_fade(
    input logic clk,
    input logic increment_state, // trigger to change color fade state
    input logic increasing_pwm, // should fade from off to on and reset once every time increment_state triggers
    output logic red,
    output logic green,
    output logic blue
);
    
    localparam ON = 1'b1;
    localparam OFF = 1'b0;

    // enum assigns increasing numbers so they go from RED to MAGENTA when incremented
    typedef enum {RED,YELLOW,GREEN,CYAN,BLUE,MAGENTA} initial_color;
    
    initial_color start_color = RED; // register with current color, which will fade to the next color before state changes 
    logic fade_on;
    logic fade_off;


    // assign colors to the correct fading/constant value state
    always_comb begin
        fade_on = increasing_pwm;
        fade_off = ~increasing_pwm; // creates PWM that fades to off
        case(start_color)
            RED:     begin red =       ON;green =  fade_on; blue =      OFF; end
            YELLOW:  begin red = fade_off;green =       ON; blue =      OFF; end
            GREEN:   begin red =      OFF;green =       ON; blue =  fade_on; end
            CYAN:    begin red =      OFF;green = fade_off; blue =       ON; end
            BLUE:    begin red =  fade_on;green =      OFF; blue =       ON; end
            MAGENTA: begin red =       ON;green =      OFF; blue = fade_off; end
            // not reached hopefully
            default: begin red = 1'bx; green = 1'bx; blue = 1'bx; end
        endcase
    end
    

    // Move to next color state when pwm ramp starts
    always_ff @(posedge clk) begin
        if(increment_state) begin
            if(start_color ==  MAGENTA) begin
                start_color <= RED;
            end
            else begin
                start_color <= initial_color'(int'(start_color) + 1);
            end
        end
    end

endmodule
