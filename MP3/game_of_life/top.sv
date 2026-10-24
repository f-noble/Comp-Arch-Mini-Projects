`default_nettype none
`include "display_memory.sv"

// led_matrix top level module

module top #(
    input logic     clk, 
    input logic     SW, 
    input logic     BOOT,
    output logic    LED,
    output logic    RGB_G,
    output logic    _48b, 
    output logic    _45a
);

    

    logic use_memory = 1'b0; // state of game
    logic write_data = 1'b0;
    logic [7:0]green_input = 8'b0;

    logic display_busy;
    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;
    logic [7:0] bitmap_red_data;
    logic [7:0] bitmap_green_data;
    logic [7:0] bitmap_blue_data;

    logic rgb_g = 1'b0;
    
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
        .bitmap_row_mem_in_red    (8'b0), 
        .bitmap_row_mem_in_green  (green_input), 
        .bitmap_row_mem_in_blue   (8'b0),
        .bitmap_row_addr_in       (3'b011), 
        .mem_in_red               (8'b0), 
        .mem_in_green             (8'b0), 
        .mem_in_blue              (8'b0),
        .addr_in                  (6'b0), 

        ._48b                     (_48b),
        ._45a                     (_45a),
        .displaying               (display_busy),
        .bitmap_row_mem_out_red   (),
        .bitmap_row_mem_out_green (),
        .bitmap_row_mem_out_blue  (),
        .mem_out_red              (),
        .mem_out_green            (),
        .mem_out_blue             ()
    );

    // when the boot button is pressed, wait until the current frame is displayed and then start using the memory
    always_ff @(posedge clk) begin
        if (~BOOT) begin
            if (~display_busy) begin
                use_memory <= 1'b1;
            end
            else begin
            use_memory <= 1'b0;
            end
        end
        else begin
            use_memory <= 1'b0;
        end

    end

    // write data from switch whenever you are able to use memory
    always_ff @(posedge clk) begin
        if(use_memory) begin
            write_data <= 1'b1;
            green_input <= { 4'b0, SW, 3'b0 };
        end
        else begin
            write_data <= 1'b0;
        end

        rgb_g <= 1'b1;
    end


    assign LED = write_data;
    assign RGB_G = green_input[3];
    // assign _48b = _;
    // assign _45a = ~ws2812b_out; // not needed unless voltage level issues

endmodule
