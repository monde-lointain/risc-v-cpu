// Load/Store Control Logic
// Generates byte enables, rotation amounts, and pipeline control signals

module ls_ctrl (
  input  logic        clk,
  input  logic        rst_n,
  
  // Inputs from instruction decode
  input  logic [31:0] address,
  input  logic        load_enable,
  input  logic        store_enable,
  input  logic        byte_op,
  input  logic        half_op,
  input  logic        unsigned_op,
  
  // EX stage outputs
  output logic        ex_load,
  output logic        ex_store,
  output logic        ex_byte_op,
  output logic        ex_half_op,
  output logic        ex_unsigned_op,
  output logic [ 1:0] ex_addr_low,
  output logic [ 1:0] ex_rotate_amount,
  
  // MEM stage outputs
  output logic        mem_load,
  output logic        mem_byte_op,
  output logic        mem_half_op,
  output logic        mem_unsigned_op,
  output logic [ 1:0] mem_rotate_amount,
  output logic [ 3:0] mem_byte_enable,
  output logic        mem_chip_sel
);

  // ========================================================================
  // EX Stage: Compute rotation amounts and byte enables
  // ========================================================================
  
  // Pipeline registers: ID -> EX
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_load       <= 1'b0;
      ex_store      <= 1'b0;
      ex_byte_op    <= 1'b0;
      ex_half_op    <= 1'b0;
      ex_unsigned_op <= 1'b0;
      ex_addr_low   <= 2'b0;
    end else begin
      ex_load       <= load_enable;
      ex_store      <= store_enable;
      ex_byte_op    <= byte_op;
      ex_half_op    <= half_op;
      ex_unsigned_op <= unsigned_op;
      ex_addr_low   <= address[1:0];
    end
  end
  
  // Compute rotation amount for stores
  // Stores rotate data right to align with memory byte lanes
  always_comb begin
    if (byte_op) begin
      // Byte stores: rotate by address[1:0]
      ex_rotate_amount = ex_addr_low;
    end else if (half_op) begin
      // Halfword stores: rotate by address[1] * 2
      ex_rotate_amount = {ex_addr_low[1], 1'b0};
    end else begin
      // Word stores: no rotation needed (must be aligned)
      ex_rotate_amount = 2'b00;
    end
  end

  // ========================================================================
  // MEM Stage: Generate memory control signals
  // ========================================================================
  
  logic [ 1:0] mem_addr_low;
  logic        mem_store;
  
  // Pipeline registers: EX -> MEM
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_load          <= 1'b0;
      mem_store         <= 1'b0;
      mem_byte_op       <= 1'b0;
      mem_half_op       <= 1'b0;
      mem_unsigned_op   <= 1'b0;
      mem_addr_low      <= 2'b0;
      mem_rotate_amount <= 2'b0;
    end else begin
      mem_load          <= ex_load;
      mem_store         <= ex_store;
      mem_byte_op       <= ex_byte_op;
      mem_half_op       <= ex_half_op;
      mem_unsigned_op   <= ex_unsigned_op;
      mem_addr_low      <= ex_addr_low;
      mem_rotate_amount <= ex_rotate_amount;
    end
  end
  
  // Generate byte enables based on operation type and address
  logic [3:0] byte_enable_raw;
  
  always_comb begin
    if (mem_byte_op) begin
      // Byte operation: enable single byte based on address[1:0]
      case (mem_addr_low)
        2'b00:   byte_enable_raw = 4'b0001;
        2'b01:   byte_enable_raw = 4'b0010;
        2'b10:   byte_enable_raw = 4'b0100;
        2'b11:   byte_enable_raw = 4'b1000;
        default: byte_enable_raw = 4'b0000;
      endcase
    end else if (mem_half_op) begin
      // Halfword operation: enable two bytes based on address[1]
      case (mem_addr_low[1])
        1'b0:    byte_enable_raw = 4'b0011;
        1'b1:    byte_enable_raw = 4'b1100;
        default: byte_enable_raw = 4'b0000;
      endcase
    end else begin
      // Word operation: enable all four bytes
      byte_enable_raw = 4'b1111;
    end
  end
  
  // Only drive byte enables during stores
  assign mem_byte_enable = mem_store ? byte_enable_raw : 4'b0000;
  
  // Chip select active when load or store is active
  assign mem_chip_sel = mem_load | mem_store;

endmodule : ls_ctrl
