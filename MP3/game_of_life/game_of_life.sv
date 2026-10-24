module game_of_life #(
    parameter FPS = 4
)(
// inputs
input logic clk,
input logic waiting_for_display
);

localparam FRAME_CYCLES = 12000000/FPS; // clock cycles per frame

localparam IDLE = 3'b100;
localparam READ_IN = 3'b010;
localparam WRITE_OUT = 3'b001;

localparam USE_MEM = 1'b0;
localparam DEC_ADDR = 1'b1;


logic [$clog2(FRAME_CYCLES)-1:0] frame_time_counter = 0;
logic [7:0] frame_counter = 0;
logic [7:0] past_game_frame = 255;
logic [2:0] state = IDLE;
logic [2:0] next_state;
logic mem_state = USE_MEM;
logic next_mem_state;
logic [2:0] mem_addr = 3'b0;

// State updates
always_ff @(posedge clk) begin
  state <= next_state;
  mem_state <= next_mem_state;
end

// ccccc meow meow meow meow mrrrrrrp mrrrrooowwwwww
// rawr
//            
//            _
//       ____/'|   -rawr
//    __/     / 
//  -/  //  //
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
    next_state = (mem_state == USE_MEM && mem_addr == 3'b1) ? WRITE_OUT : READ_IN;
  end
  else if (state == WRITE_OUT) begin
    next_state = (mem_state == USE_MEM && mem_addr == 3'b1) ? IDLE : WRITE_OUT;
  end
  
  if (state == READ_IN || state == WRITE_OUT) begin
    if (mem_state == USE_MEM) begin
      next_mem_state = DEC_ADDR;
    end
    else begin
      next_mem_state = USE_MEM;
    end
  end
  else begin
    next_mem_state = USE_MEM;
  end
end

// updating registers dependent on state
always_ff @(posedge clk) begin
  if(mem_state == DEC_ADDR) begin
    mem_addr <= mem_addr + 3'b110; // overflow aka subtract 1
  end
  else if(state !== next_state) begin
    mem_addr <= 3'b000;
  end
  if (state == READ_IN && mem_addr == 3'b000) begin
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

endmodule
