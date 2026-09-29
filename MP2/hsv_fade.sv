// Fades the RGB LEDs on the board between 6 colors around the HSV color wheel every second, using a periodically increasing pwm input

module hsv_fade(
    input logic clk,
    input logic increment_state, // change which color fade state
    input logic increasing_pwm, // should fade from off to on restarting every next_state
    output logic red,
    output logic green,
    output logic blue
);
    
    // LED_ON = 1'b0; // LED is active low so this turns it on
    // parameter LED_OFF = 1'b1;
    localparam ON = 1'b1;
    localparam OFF = 1'b0;

    // enum assigns increasing numbers so they go from RED to MAGENTA when incremented
    typedef enum {RED,YELLOW,GREEN,CYAN,BLUE,MAGENTA} initial_color;
    
    initial_color start_color = RED; // register with current color 
    logic fade_on;
    logic fade_off;


// Provides pwm that increases linearly from 0% to 100% duty cycle every stroke
    // pwm_ramp ramps(
        // .clk            (clk), 
        // .increasing_pwm (fade_on)
    // )

    always_comb begin // combinational logic values that are always true
        fade_on = increasing_pwm;
        fade_off = ~increasing_pwm;
        // set color constantly with combinational case statement
        case(start_color)
            RED:     begin red = ON      ;green =  fade_on; blue =      OFF; end
            YELLOW:  begin red = fade_off;green =       ON; blue =      OFF; end
            GREEN:   begin red =      OFF;green =       ON; blue =  fade_on; end
            CYAN:    begin red =      OFF;green = fade_off; blue =       ON; end
            BLUE:    begin red =  fade_on;green =      OFF; blue =       ON; end
            MAGENTA: begin red = ON      ;green =      OFF; blue = fade_off; end
            // not reached hopefully
               // RED: begin red=fade_on;green=fade_on;blue=fade_on;end
               // YELLOW: begin red=fade_off;green=fade_off;blue=fade_off;end
            default: begin red = 1'bx; green = 1'bx; blue = 1'bx; end
        endcase
    end

    always_ff @(posedge clk) begin // update color state when pwm ramp restarts
        if(increment_state) begin
            // restart with first color or go to the next color in sequence
            if(start_color ==  MAGENTA) begin
                start_color <= RED;
            end
            else begin
                // start_color <= start_color.next();
                start_color <= initial_color'(int'(start_color) + 1);
            end
        end
    end

endmodule
