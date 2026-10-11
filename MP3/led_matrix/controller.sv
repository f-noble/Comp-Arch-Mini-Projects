// orchestrates loading pixels to shift register for each frame, handles delays to set FPS, and tells driver when to transmit loaded pixels
module controller (
    input logic clk, 
    output logic load_sreg, // asserted for a clock cycle when the pixel value at the current frame should be transmitted
    output logic transmit_pixel, // asserted for TRANSMIT_CYCLES cycles to instruct the driver to request and transmit the pixel rgb value from the shift register to the matrix
    output logic [5:0] pixel, // index of current pixel to send
    output logic [4:0] frame // index of current frame to take that pixel information from
);

    localparam TRANSMIT_FRAME       = 1'b0;
    localparam IDLE                 = 1'b1;

    localparam [2:0] READ_CH_VALS   = 3'b001;
    localparam [2:0] LOAD_SREG      = 3'b010;
    localparam [2:0] TRANSMIT_PIXEL = 3'b100;

    localparam [8:0] TRANSMIT_CYCLES    = 9'd360;       // = 24 bits / pixel x 15 cycles / bit
    localparam [19:0] IDLE_CYCLES       = 20'd351832;   // = 375000 - 64 x (360 + 2) for 32 frames / second

    logic state = TRANSMIT_FRAME;
    logic next_state;

    logic [2:0] transmit_phase = READ_CH_VALS;
    logic [2:0] next_transmit_phase;

    logic [5:0] pixel_counter = 6'd0;
    logic [4:0] frame_counter = 5'd0;
    logic [8:0] transmit_counter = 9'd0;
    logic [19:0] idle_counter = 20'd0;

    logic transmit_pixel_done;
    logic idle_done;

    
    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1);
    assign idle_done = (idle_counter == IDLE_CYCLES - 1);

    // set states from combinational logic each cycle
    always_ff @(negedge clk) begin
        state <= next_state;
        transmit_phase <= next_transmit_phase;
    end

    // set state transitions for idle vs. transmitting
    always_comb begin
        next_state = 1'bx;
        unique case (state)
            TRANSMIT_FRAME: // become idle when all pixels finish transmitting
                if ((pixel_counter == 6'd63) && (transmit_pixel_done))
                    next_state = IDLE;
                else
                    next_state = TRANSMIT_FRAME;
            IDLE: // start transmitting when full time for a frame has elapsed
                if (idle_done)
                    next_state = TRANSMIT_FRAME;
                else
                    next_state = IDLE;
        endcase
    end

    // set state transitions for while transmitting
    always_comb begin
        next_transmit_phase = READ_CH_VALS;
        if (state == TRANSMIT_FRAME) begin
            case (transmit_phase)
                READ_CH_VALS: // delay a clock cycle so memory output can update to the next pixel value
                    next_transmit_phase = LOAD_SREG;
                LOAD_SREG: // on this clock cycle the next pixel value is loaded onto the shift register
                    next_transmit_phase = TRANSMIT_PIXEL;
                TRANSMIT_PIXEL: // wait for pixel to be transmitted, then go to next pixel at the end
                    next_transmit_phase = transmit_pixel_done ? READ_CH_VALS : TRANSMIT_PIXEL;
            endcase
        end
    end

    // increment index of pixel memory to transmit each time a pixel has been transmitted
    always_ff @(negedge clk) begin
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done) begin
            pixel_counter <= pixel_counter + 1;
        end
    end

    // after waiting for a frame to be done, index memory representing next frame
    always_ff @(negedge clk) begin
        if (idle_done) begin
            frame_counter <= frame_counter + 1;
        end
    end

    // count how many cycles pixels have been transmitting for 
    always_ff @(negedge clk) begin
        if (transmit_phase == TRANSMIT_PIXEL) begin
            transmit_counter <= transmit_counter + 1;
        end
        else begin
            transmit_counter <= 9'd0;
        end
    end

    // count how many cycles have gone by since the last pixel this frame finished transmitting
    always_ff @(negedge clk) begin
        if (state == IDLE) begin
            idle_counter <= idle_counter + 1;
        end
        else begin
            idle_counter <= 20'd0;
        end
    end

    
    assign pixel = pixel_counter;
    assign frame = frame_counter;

    assign load_sreg = (transmit_phase == LOAD_SREG);
    assign transmit_pixel = (transmit_phase == TRANSMIT_PIXEL);

endmodule
