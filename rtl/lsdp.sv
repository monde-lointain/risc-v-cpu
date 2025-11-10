// Load/Store Datapath
// Handles data rotation and alignment for loads and stores

module ls_datapath (
  input  logic        clk,
  
  // Store path inputs
  input  logic [31:0] store_data,
  input  logic [ 1:0] ex_rotate_amount,
  
  // Load path inputs
  input  logic [31:0] mem_read_data,
  input  logic [ 1:0] mem_rotate_amount,
  input  logic        mem_byte_op,
  input  logic        mem_half_op,
  input  logic        mem_unsigned_op,
  
  // Outputs
  output logic [31:0] mem_write_data,
  output logic [31:0] load_data
);

  // ========================================================================
  // Store Path: Rotate data right to align with memory
  // ========================================================================
  
  logic [31:0] store_rotated;
  
  always_comb begin
    case (ex_rotate_amount)
      2'b00:   store_rotated = store_data;                              // No rotation
      2'b01:   store_rotated = {store_data[7:0],   store_data[31:8]};  // Rotate right 1 byte
      2'b10:   store_rotated = {store_data[15:0],  store_data[31:16]}; // Rotate right 2 bytes
      2'b11:   store_rotated = {store_data[23:0],  store_data[31:24]}; // Rotate right 3 bytes
      default: store_rotated = store_data;
    endcase
  end
  
  // Pipeline register: EX -> MEM
  always_ff @(posedge clk) begin
    mem_write_data <= store_rotated;
  end

  // ========================================================================
  // Load Path: Rotate and sign/zero extend data from memory
  // ========================================================================
  
  logic [31:0] load_rotated;
  logic [31:0] load_extended;
  
  // Rotate left to align data (opposite of store rotation)
  always_comb begin
    case (mem_rotate_amount)
      2'b00:   load_rotated = mem_read_data;                              // No rotation
      2'b01:   load_rotated = {mem_read_data[23:0], mem_read_data[31:24]}; // Rotate left 1 byte
      2'b10:   load_rotated = {mem_read_data[15:0], mem_read_data[31:16]}; // Rotate left 2 bytes
      2'b11:   load_rotated = {mem_read_data[7:0],  mem_read_data[31:8]};  // Rotate left 3 bytes
      default: load_rotated = mem_read_data;
    endcase
  end
  
  // Sign or zero extend based on operation type
  always_comb begin
    if (mem_byte_op) begin
      // Byte load: extend bit [7]
      if (mem_unsigned_op) begin
        load_extended = {24'h0, load_rotated[7:0]};  // Zero extend
      end else begin
        load_extended = {{24{load_rotated[7]}}, load_rotated[7:0]};  // Sign extend
      end
    end else if (mem_half_op) begin
      // Halfword load: extend bit [15]
      if (mem_unsigned_op) begin
        load_extended = {16'h0, load_rotated[15:0]};  // Zero extend
      end else begin
        load_extended = {{16{load_rotated[15]}}, load_rotated[15:0]};  // Sign extend
      end
    end else begin
      // Word load: no extension needed
      load_extended = load_rotated;
    end
  end
  
  // Pipeline register: MEM -> WB
  always_ff @(posedge clk) begin
    load_data <= load_extended;
  end

endmodule : ls_datapath
