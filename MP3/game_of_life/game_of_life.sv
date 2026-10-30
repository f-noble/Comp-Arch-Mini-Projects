// Iterates on conway's game of life at a set FPS
// game state is sent to be stored in 8 consecutive bytes in memory
// uses an 8x8 grid, where neighbors on the edges of the grid
// wrap around to make it act more like an infinite grid
// data on which cells die and how can be stored in different memory grids

module game_of_life #(
    parameter FPS = 8
)(
// inputs
input logic clk,
input logic waiting_for_display,
input logic[7:0] mem_in,
output logic [2:0] address,
output logic[7:0] write_data,
output logic[7:0] write_underpopulation_data,
output logic[7:0] write_overpopulation_data,
output logic write_to_mem,
output logic using_memory
);

localparam FRAME_CYCLES = 12000000/FPS; // clock cycles per frame

// States
localparam IDLE = 3'b100; // wait for next frame
localparam READ_IN = 3'b010; // read data from the memory
localparam WRITE_OUT = 3'b001; // find next game state and write to memory

// READ_IN and WRITE_OUT sub-states
localparam USE_MEM = 1'b0; // write to memory or read from it
localparam INC_ADDR = 1'b1; // change the byte requested from memory


logic [$clog2(FRAME_CYCLES)-1:0] frame_time_counter = 0;
logic [7:0] frame_counter = 0;
logic [7:0] past_game_frame = 255;
logic [2:0] state = IDLE;
logic [2:0] next_state;
logic mem_state = USE_MEM;
logic next_mem_state;
logic [3:0] mem_addr = 4'b0;
logic [63:0] last_game_state = 64'b0;
logic [7:0] next_game_state;
logic [63:0] underpopulations = 64'b0;
logic [7:0] next_underpopulation_data;
logic [63:0] overpopulations = 64'b0;
logic [7:0] next_overpopulation_data;


// State updates
always_ff @(posedge clk) begin
  state <= next_state;
  mem_state <= next_mem_state;
end

// state transition conditions
always_comb begin
  next_state = 3'bxxx;
  if (state == IDLE) begin
    if((~waiting_for_display) && (frame_counter !== past_game_frame)) begin
    next_state = READ_IN;
    end
    else begin
    next_state = IDLE;
     end
  end
  else if (state == READ_IN) begin
    next_state = (mem_state == USE_MEM && mem_addr == 4'b1000) ? WRITE_OUT : READ_IN;
  end
  else if (state == WRITE_OUT) begin
    next_state = (mem_state == USE_MEM && mem_addr == 4'b1000) ? IDLE : WRITE_OUT;
  end
  
  if (state == READ_IN || state == WRITE_OUT) begin
    if (mem_state == USE_MEM) begin
      next_mem_state = INC_ADDR;
    end
    else begin
      next_mem_state = USE_MEM;
    end
  end
  else begin
    next_mem_state = USE_MEM;
  end
end

// incrementing memory address to be read from or written to
always_ff @(posedge clk) begin
  if (next_mem_state == INC_ADDR && mem_addr !== 4'b1000) begin
    mem_addr <= mem_addr + 4'b0001; 
  end
  else if (next_mem_state == INC_ADDR || next_state == IDLE) begin
    mem_addr <= 4'b0000;
  end
  if (state == READ_IN && mem_addr == 4'b0000) begin
    past_game_frame <= frame_counter;
  end
end

// increment frame_counter every frame
always_ff @(posedge clk) begin
  if(frame_time_counter == FRAME_CYCLES - 1) begin
    frame_counter <= frame_counter + 1;
    frame_time_counter <= 0;
  end
  else begin
    frame_time_counter <= frame_time_counter + 1;
    end
end

// loading game state from memory 1 byte/memory location at a time
always_ff @(posedge clk) begin
  if (state == READ_IN && mem_state == USE_MEM) begin
    last_game_state[7:0] <= mem_in;
  end
  else if ( (state == READ_IN || state == WRITE_OUT) && mem_state == INC_ADDR) begin
    for (int i=0; i<64; i++) begin // shift each row up, wrapping from top to bottom
      if (i-8 < 0) begin
        last_game_state[64+(i-8)] <= last_game_state[i];
        underpopulations[64+(i-8)] <= underpopulations[i];
        overpopulations[64+(i-8)] <= overpopulations[i];
      end
      else begin
        last_game_state[i-8] <= last_game_state[i];
        underpopulations[i-8] <= underpopulations[i];
        overpopulations[i-8] <= overpopulations[i];
      end
    end
  end
end


// calculate next state of the game relative to each row
always_comb begin
  next_underpopulation_data = 8'b0;
  next_overpopulation_data = 8'b0;
  next_game_state = 8'b0;
  for (int i=0; i<8; i++) begin

    case(
      last_game_state[56+(i+1)%8] + // right
      last_game_state[63-(8-i)%8] + // left
      last_game_state[(i+1)%8] +    // bottom right
      last_game_state[7-(8-i)%8] +  // bottom left
      last_game_state[48+(i+1)%8] + // top right 
      last_game_state[55-(8-i)%8] + // top left
      last_game_state[i] +          // bottom
      last_game_state[48+i]         // top
    )
    0: // only if alive and then dies of underpopulation
      next_underpopulation_data[i] = last_game_state[56+i] == 1'b1;
    1: // only if alive and then dies of underpopulation
      next_underpopulation_data[i] = last_game_state[56+i] == 1'b1;
    2: // stays alive if previously alive
      next_game_state[i] = last_game_state[56+i] == 1'b1;
    3: // stays alive or becomes alive
      next_game_state[i] = 1'b1;
    default: // only if alive and then dies of overpopulation
      begin
        next_game_state[i] = 1'b0;
        next_overpopulation_data[i] = last_game_state[56+i] == 1'b1;
      end
    endcase
    // for reference
    // next_game_state[i] = last_game_state[(56+i+1)%64]; // increments index by 1 each time
  end
end

// set outputs to be sent to memory module
assign write_data = {next_game_state};
assign write_underpopulation_data = {next_underpopulation_data};
assign write_overpopulation_data = {next_overpopulation_data};

assign write_to_mem = (state == WRITE_OUT && mem_state == USE_MEM);

assign using_memory = ~(state == IDLE && next_state == IDLE);

assign address = mem_addr[2:0];

endmodule
