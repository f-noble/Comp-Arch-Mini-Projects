`default_nettype none
`include "memory.sv"
`include "ws2812b.sv"
`include "controller.sv"

// led_matrix top level module

module display_memory(
    input logic     clk, 
    input logic     SW, 
    input logic     BOOT,
    input logic     bitmap_mode,
    input logic     set_in_use,
    input logic     write_data,
    input logic     [7:0] bitmap_row_mem_in_red,
    input logic     [7:0] bitmap_row_mem_in_green,
    input logic     [7:0] bitmap_row_mem_in_blue,
    input logic     [2:0] bitmap_row_addr_in, // assign row by row
    input logic     [7:0] mem_in_red,
    input logic     [7:0] mem_in_green,
    input logic     [7:0] mem_in_blue,
    input logic     [5:0] addr_in,

    output logic    _48b, 
    output logic    _45a,
    output logic    displaying,
    output logic    [7:0] bitmap_row_mem_out_red, 
    output logic    [7:0] bitmap_row_mem_out_green, 
    output logic    [7:0] bitmap_row_mem_out_blue, 
    output logic    mem_out_red, 
    output logic    mem_out_green, 
    output logic    mem_out_blue
);

    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;

    logic [7:0] green_bmp_data;

    logic [7:0] green_output;

    logic [5:0] pixel;
    logic [10:0] display_address;
    logic [10:0] bitmap_address;

    logic bitmap_write;
    logic mem_write;
    
    logic [10:0] address;
    logic ready_to_display;
    logic done_displaying;
    logic display_using_memory = 1'b1;

    logic [23:0] shift_reg = 24'd0;
    logic load_sreg;
    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;

    // Memory location to be read from memory of each of the colors
    // bitmap_mode represents each row with a single memory address
    always_comb begin
        if (bitmap_mode) begin
            display_address = { 5'b0, 3'b0, pixel[5:3] };
            green_output = { 8{green_bmp_data[{5'b0,pixel[2:0]}]} };
        end
        else begin
            display_address = { 5'b0, pixel };
            green_output = green_data;
        end
    end

    assign bitmap_row_mem_out_green = green_bmp_data;

    
    memory #(
        .INIT_FILE      ("testing_bitmap_mode.txt")
    ) u0 (
        .clk            (clk),
        .read_address   (bitmap_address),
        .write          (bitmap_write),
        .write_data     (bitmap_row_mem_in_green), 
        .read_data      (green_bmp_data)
    );

    // Instance sample memory for red channel
    memory #(
        .INIT_FILE      ("spiral/red.txt")
    ) u1 (
        .clk            (clk),
        .read_address   (address),
        .write          (1'b0),
        .write_data     (8'b0),
        .read_data      (red_data)
    );

    // Instance sample memory for green channel
    memory #(
        .INIT_FILE      ("spiral/green.txt")
    ) u2 (
        .clk            (clk), 
        .read_address   (address), 
        .write          (bitmap_write),
        .write_data     (bitmap_row_mem_in_green),
        .read_data      (green_data)
    );

    // Instance sample memory for blue channel
    memory #(
        .INIT_FILE      ("spiral/blue.txt")
    ) u3 (
        .clk            (clk), 
        .read_address   (address), 
        .write          (1'b0),
        .write_data     (8'b0),
        .read_data      (blue_data)
    );

    // Instance the WS2812B output driver
    ws2812b u4 (
        .clk            (clk), 
        .serial_in      (shift_reg[23]), 
        .transmit       (transmit_pixel), 
        .ws2812b_out    (ws2812b_out), 
        .shift          (shift)
    );

    // Instance the controller
    controller u5 (
        .clk              (clk), 
        .load_sreg        (load_sreg), 
        .transmit_pixel   (transmit_pixel),
        .ready_to_display (ready_to_display),
        .done_displaying  (done_displaying),
        .pixel            (pixel)
    );

    // set state to displaying memory unless the memory is being used
    always_ff @(negedge clk) begin
        if (~set_in_use && ready_to_display) begin
            display_using_memory <= 1'b1;
        end
        else if (done_displaying) begin
            display_using_memory <= 1'b0;
        end
    end

    // if the memory is being used, disconnect data being pushed to display and address being set by controller
    // allow externally driven writes and memory addressing in bitmap or full color mode
    always_comb begin
        if (display_using_memory) begin
            _48b = ws2812b_out;
            _45a = ~ws2812b_out;
            address = display_address;
            bitmap_address = display_address;
            bitmap_write = 1'b0;
            mem_write = 1'b0;
        end
        else begin
            _48b = 1'b0;
            _45a = 1'b1;
            bitmap_address = { 5'b0, 3'b0, bitmap_row_addr_in };
            address = { 5'b0, addr_in };


            if (bitmap_mode) begin
                bitmap_write = write_data;
                mem_write = 1'b0;
            end
            else begin
                bitmap_write = 1'b0;
                mem_write = write_data;
            end
        end
    end

    assign displaying = display_using_memory;

    always_ff @(posedge clk) begin // pass matrix color assignments from memory to shift register when requested by controller
        if (load_sreg) begin // Only shows 3 MSB of colors to reduce brightness
            // unique case ({ SW, BOOT })
                // 2'b00: // show green only when BOOT and SW pressed
                    // shift_reg <= { 5'd0, green_output[7:5], 16'd0 };
                // 2'b01: // show red only when SW pressed
                    // shift_reg <= { 8'd0, 5'd0, red_data[7:5], 8'd0 };
                // 2'b10: // show blue only when BOOT pressed
                    // shift_reg <= { 16'd0, 5'd0 ,blue_data[7:5] };
                // 2'b11: // show full colors
                // CORRECT LINE: 
                    // shift_reg <= { 5'd0, green_output[7:5], 5'd0, red_data[7:5], 5'd0, blue_data[7:5] };
                    shift_reg <= { 5'd0, green_output[7:5], 16'd0 };
            // endcase
        end
        else if (shift) begin // shift to next bit when requested by driver
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

    // assign _48b = ws2812b_out;
    // assign _45a = ~ws2812b_out; // not needed unless voltage level issues

endmodule
