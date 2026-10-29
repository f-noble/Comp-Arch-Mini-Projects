`default_nettype none
`include "display_memory.sv"
`include "game_of_life.sv"

// led_matrix top level module

module top (
    input logic     clk, 
    input logic     SW, 
    input logic     BOOT,
    // output logic    LED,
    // output logic    RGB_G,
    output logic    _48b, 
    output logic    _45a
);

    

    logic use_memory; // state of game
    logic write_data;
    logic [7:0] green_input;
    logic [7:0] blue_input;
    logic [7:0] red_input;

    logic display_busy;
    logic [2:0] bmp_address;
    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;
    logic [7:0] bitmap_red_data;
    logic [7:0] bitmap_green_data;
    logic [7:0] bitmap_blue_data;

    // logic rgb_g = 1'b0;
    
    // Memory location to be read from memory of each of the colors
    // assign address = { 5'b0 , pixel };

    // Instance the controller
    display_memory u1 (
        .clk                      (clk),
        .SW                       (SW),
        .BOOT                     (BOOT),
        .bitmap_mode              (1'b1),
        .set_in_use               (use_memory),
        .write_data               (write_data),
        .bitmap_row_mem_in_red    (red_input), 
        .bitmap_row_mem_in_green  (green_input), 
        .bitmap_row_mem_in_blue   (blue_input),
        .bitmap_row_addr_in       (bmp_address), 
        .mem_in_red               (8'b0), 
        .mem_in_green             (8'b0), 
        .mem_in_blue              (8'b0),
        .addr_in                  (6'b0), 

        ._48b                     (_48b),
        ._45a                     (_45a),
        .displaying               (display_busy),
        .bitmap_row_mem_out_red   (bitmap_red_data),
        .bitmap_row_mem_out_green (bitmap_green_data),
        .bitmap_row_mem_out_blue  (bitmap_blue_data),
        .mem_out_red              (),
        .mem_out_green            (),
        .mem_out_blue             ()
    );

    game_of_life u2 (
        .clk                 (clk),
        .waiting_for_display (display_busy),
        
        .mem_in                     (bitmap_green_data),
        .address                    (bmp_address),
        .write_data                 (green_input),
        .write_underpopulation_data (blue_input),
        .write_overpopulation_data  (red_input),
        .write_to_mem               (write_data),
        .using_memory               (use_memory)
    );

    // when the boot button is pressed, wait until the current frame is displayed and then start using the memory
    // always_ff @(posedge clk) begin
        // if (~BOOT) begin
            // if (~display_busy) begin
                // use_memory <= 1'b1;
            // end
            // else begin
            // use_memory <= 1'b0;
            // end
        // end
        // else begin
            // use_memory <= 1'b0;
        // end

    // end

    // write data from switch whenever you are able to use memory
    // always_ff @(posedge clk) begin
        // if(use_memory) begin
            // write_data <= 1'b1;
            // green_input <= { 4'b0, SW, 3'b0 };
        // end
        // else begin
            // write_data <= 1'b0;
        // end

        // rgb_g <= 1'b1;
    // end


    // assign LED = write_data;
    // assign RGB_G = green_input[3];
    // assign _48b = _;
    // assign _45a = ~ws2812b_out; // not needed unless voltage level issues

endmodule
