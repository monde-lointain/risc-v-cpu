//==============================================================================
// Description: Load/Store Datapath
//              Handles data muxing and rotation for scalar and vector
//              load/store operations between register files and data memory
//==============================================================================

module lsdp (
  input  logic         clk,

  // EX Stage Inputs
  input  logic        ex_su_byte_ls,       // SU byte load/store
  input  logic        ex_su_half_ls,       // SU half-word load/store
  input  logic [31:0] mem_write_data,      // Memory write data
  input  logic [ 1:0] ex_rot,              // EX rotation amount

  // WB Stage Inputs
  input  logic [ 1:0] wb_rot,              // WB rotation amount
  input  logic        wb_su_uns_ls,        // SU unsigned load/store
  input  logic        wb_su_load,          // SU load operation
  input  logic [31:0] dmem_dataout,        // Data memory output
  input  logic        ls_drive_ls,         // Drive ls_data bus

  // Bidirectional Buses
  input  logic [31:0] ls_data,             // Load/store data bus (input)
  output tri   [31:0] ls_data_out,         // Load/store data bus (output)

  // Outputs
  output logic [31:0] df_datain,           // Final store data to DMEM
  output logic [31:0] dmem_rd_data         // DMEM read data
);

  //----------------------------------------------------------------------------
  // Internal Signals
  //----------------------------------------------------------------------------

  // Store Datapath (to DMEM)
  logic [31:0] dma_data_to_dmem;
  logic [31:0] store_rotated;

  // Load Datapath (from DMEM)
  logic [127:0] wb_datain;
  logic [127:0] wb_datain_sxt;              // Sign-extended
  logic [127:0] dmem_to_dp_1st;             // After word rotation
  logic [127:0] dmem_to_dp_2nd;             // After byte rotation
  logic [127:0] load_data;
  logic [127:0] load_data_reg;

  // DMA Interface
  logic [ 63:0] sec_rd_data;
  logic [ 63:0] secondary_write_data;

  // Pipeline Registers
  logic         df_su_byte_ls;
  logic         df_su_half_ls;
  logic         wb_su_byte_ls;
  logic         wb_su_half_ls;

  //============================================================================
  // Store Datapath (Register File -> Data Memory)
  //============================================================================

  
  always_comb begin
    case (ex_rotate_amount)
      2'b00:   store_rotated = store_data;                              // No rotation
      2'b01:   store_rotated = {store_data[7:0],   store_data[31:8]};  // Rotate right 1 byte
      2'b10:   store_rotated = {store_data[15:0],  store_data[31:16]}; // Rotate right 2 bytes
      2'b11:   store_rotated = {store_data[23:0],  store_data[31:24]}; // Rotate right 3 bytes
      default: store_rotated = store_data;
    endcase
  end

  //----------------------------------------------------------------------------
  // EX -> DF Pipeline
  //----------------------------------------------------------------------------

  always_ff @(posedge clk) begin
    df_su_byte_ls <= ex_su_byte_ls;
    df_su_half_ls <= ex_su_half_ls;
    df_datain     <= store_rotated;
  end

  //----------------------------------------------------------------------------
  // DF -> WB Pipeline
  //----------------------------------------------------------------------------

  always_ff @(posedge clk) begin
    wb_su_byte_ls <= df_su_byte_ls;
    wb_su_half_ls <= df_su_half_ls;
    wb_datain     <= df_datain;
  end

  //============================================================================
  // Load Datapath (Data Memory -> Register File)
  //============================================================================

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

  // Sign extension control (mutual exclusion assumed)
  logic wb_sxt_half;
  logic wb_sxt_byte;

  assign wb_sxt_half = wb_su_load && wb_su_half_ls;
  assign wb_sxt_byte = wb_su_load && wb_su_byte_ls;

  // Sign or zero extend based on operation type
  always_comb begin
    if (wb_sxt_byte) begin
      // Byte load: extend bit [7]
      if (wb_su_uns_ls) begin
        load_extended = {24'h0, load_rotated[7:0]};  // Zero extend
      end else begin
        load_extended = {{24{load_rotated[7]}}, load_rotated[7:0]};  // Sign extend
      end
    end else if (wb_sxt_half) begin
      // Halfword load: extend bit [15]
      if (wb_su_uns_ls) begin
        load_extended = {16'h0, load_rotated[15:0]};  // Zero extend
      end else begin
        load_extended = {{16{load_rotated[15]}}, load_rotated[15:0]};  // Sign extend
      end
    end else begin
      // Word load: no extension needed
      load_extended = load_rotated;
    end
  end

  assign load_data = load_extended;

  // Output to ls_data Bus
  assign ls_data_out = ls_drive_ls ? load_data : 'z;

  //============================================================================
  // DMA Interfaces
  //============================================================================

  //----------------------------------------------------------------------------
  // DMA: DMEM to RDRAM
  //----------------------------------------------------------------------------

  always_ff @(posedge clk) begin
    sec_rd_data <= dmem_to_dp_1st[63:0];
  end

  assign dmem_rd_data = 

  //----------------------------------------------------------------------------
  // DMA: RDRAM to DMEM
  //----------------------------------------------------------------------------

  always_ff @(posedge clk) begin
    secondary_write_data <= mem_write_data;
  end

  assign dma_data_to_dmem = {secondary_write_data, mem_write_data};

endmodule : lsdp
