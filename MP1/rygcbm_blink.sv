// Cycles the RGB LEDs on the board around 6 colors on the HSV color wheel every second

module top(
    input logic     clk, 
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
    );

    // CLK frequency is 12MHz, so 2,000,000 cycles is 1/6 s
    parameter BLINK_INTERVAL = 2000000; // time between color switches

    parameter LED_ON = 1'b0; // LED is active low so this turns it on
    parameter LED_OFF = 1'b1;

    // enum assigns increasing numbers so they go from RED to MAGENTA when incremented
    typedef enum {RED,YELLOW,GREEN,CYAN,BLUE,MAGENTA} colors;
    
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0; // determine  size of counter register
    colors color = RED; // register with current color

    always_comb begin // combinational logic values that are always true
        // set color constantly with combinational case statement
        case(color)
            RED:     begin RGB_R = LED_ON;RGB_G = LED_OFF; RGB_B = LED_OFF; end
            YELLOW:  begin RGB_R = LED_ON;RGB_G = LED_ON; RGB_B = LED_OFF; end
            GREEN:   begin RGB_R = LED_OFF;RGB_G = LED_ON; RGB_B = LED_OFF; end
            CYAN:    begin RGB_R = LED_OFF;RGB_G = LED_ON; RGB_B = LED_ON; end
            BLUE:    begin RGB_R = LED_OFF;RGB_G = LED_OFF; RGB_B = LED_ON; end
            MAGENTA: begin RGB_R = LED_ON;RGB_G = LED_OFF; RGB_B = LED_ON; end
            // all off -- not reached hopefully
            default: begin RGB_R = LED_OFF; RGB_G = LED_OFF; RGB_B = LED_OFF; end
        endcase
    end

    always_ff @(posedge clk) begin // sequential logic
    
        if (count == BLINK_INTERVAL - 1) begin // reset counter and update color
            count <= 0;

            // restart with first color or go to the next color in sequence
            if(color ==  MAGENTA) begin
                color <= RED;
            end
            else begin
                color <= color + 1;
            end
            
        end

        else begin // tick counter up
            count <= count + 1;
        end

    end

endmodule
