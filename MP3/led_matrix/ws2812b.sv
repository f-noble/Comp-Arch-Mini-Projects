module ws2812b( // LED matrix driver
    input logic clk, 
    input logic serial_in, // should be final element in a shift register containing data to transmit
    input logic transmit, // set to 1 when shift register is preloaded with data and don't set to 0 until shift register is cleared (MAX_CYCLE_COUNT*SHIFT_REG_SIZE clock cycles)
    output logic ws2812b_out, // connect to fpga output pin
    output logic shift // send/shift next output to serial_in on the clock cycle when shift is asserted
);

    localparam IDLE = 1'b0;
    localparam TRANSMITTING = 1'b1;

    localparam T0_CYCLE_COUNT = 4'd5;
    localparam T1_CYCLE_COUNT = 4'd10;
    localparam MAX_CYCLE_COUNT = 4'd15;

    logic state = IDLE;
    logic [3:0] cycle_count = 4'd0;
    logic bit_being_sent = 1'b0;

    always_ff @(posedge clk) begin
        unique case (state)
            IDLE: // when transmit is first set, move out of idle and load first bit
                if (transmit == 1'b1) begin
                    state <= TRANSMITTING;
                    cycle_count <= 4'd0;
                    bit_being_sent <= serial_in;
                end
            TRANSMITTING: // when transmit unasserted, go immediately to idle
                if (transmit == 1'b0) begin
                    state <= IDLE;
                end
                else if (cycle_count == MAX_CYCLE_COUNT - 1) begin // save bit and reset count for next cycle
                    cycle_count <= 4'd0;
                    bit_being_sent <= serial_in;
                end
                else begin // count cycles that have already been transmitted when transmitting
                    cycle_count <= cycle_count + 1;
                end
        endcase
    end

    // send 5 cycles on, 5 cycles based on bit to send, 5 cycles off
    always_comb begin
        if (state == TRANSMITTING)
            if (bit_being_sent == 1'b0)
                ws2812b_out = (cycle_count < T0_CYCLE_COUNT);
            else
                ws2812b_out = (cycle_count < T1_CYCLE_COUNT);
        else // send zeros when not transmitting -- LED matrix wil latch values it has saved when it doesn't see more ones
            ws2812b_out = 1'b0;
    end

    // request next bit when transmitting each time cycle_count is reset
    assign shift = (state == TRANSMITTING) && (cycle_count == 4'd0);

endmodule
