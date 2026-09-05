// Cycles the RGB LEDs on the board around the HSV color wheel every second

module top(
    input logic     clk, 
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
    );

    // CLK frequency is 12MHz, so 2,000,000 cycles is 1/6 s
    parameter BLINK_INTERVAL = 2000000; // constant blink interval parameter
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0; // determine  size of counter register
    reg [7:0] color = 2; // register with current color between 2-7

    initial begin //run this once if simulating
        RGB_R = 1'b0; // turn (active low) red LED on by setting it to a digital zero
        RGB_G = 1'b0;
        RBG_B = 1'b0;
    end

    always_comb begin // combinational logic values that are always true
        // assign color with combinational case statement (note that 0 is on 1 is off)
        case(color)
            2: begin RGB_R = 1'b0;RGB_G = 1'b1; RGB_B = 1'b1; end // RED
            3: begin RGB_R = 1'b0;RGB_G = 1'b0; RGB_B = 1'b1; end // YELLOW
            4: begin RGB_R = 1'b1;RGB_G = 1'b0; RGB_B = 1'b1; end // GREEN
            5: begin RGB_R = 1'b1;RGB_G = 1'b0; RGB_B = 1'b0; end // CYAN
            6: begin RGB_R = 1'b1;RGB_G = 1'b1; RGB_B = 1'b0; end // BLUE
            7: begin RGB_R = 1'b0;RGB_G = 1'b1; RGB_B = 1'b0; end // MAGENTA
            default: begin RGB_R = 1'b1; RGB_G = 1'b1; RGB_B = 1'b1; end // off -- not reached hopefully
        endcase
    end

    always_ff @(posedge clk) begin // sequential logic
    
        if (count == BLINK_INTERVAL - 1) begin // reset counter and update color
            count <= 0;

            // go to the next color in sequence
            if(color == 7) begin
                color <= 2;
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
