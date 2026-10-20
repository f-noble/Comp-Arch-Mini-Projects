// Creates a Block RAM memory block and initializes it with INIT_FILE
// Avoid adding to this file because it may not recognize as EBR creation
module memory #(
    parameter INIT_FILE = "" // text file that should have 1 word per line
)(
    input logic clk,
    input logic [10:0] read_address,
    input logic write,
    input logic [7:0] write_data,
    output logic [7:0] read_data // set to value at read_address after every clock cycle
);

    // width of 8 bits, depth of 2048 addresses
    logic [7:0] mem [0:2047];
    
    initial if (INIT_FILE) begin
        $readmemh(INIT_FILE, mem); // put INIT_FILE contents into memory module
    end

    always_ff @(posedge clk) begin // read_data available after a clock cycle
        read_data <= mem[read_address];
    end

    always_ff @(posedge clk) begin
        if (write) begin
            mem[read_address] <= write_data;
        end
    end

endmodule
