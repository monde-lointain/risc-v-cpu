/***********************************************************************
  Interface controller between IMEM/DMEM and external buses
  Manages DMA transactions and CBUS/DBUS interfaces
 ***********************************************************************/

module busses (
  // Clock and Reset
  input  logic        clk,
  input  logic        rst_n,

  // DMA Control Signals
  input  logic        cbus_write_enable,  // Enable CBUS write
  input  logic        dbus_read_enable,   // Enable DBUS read
  input  logic        dbus_write_enable,  // Enable DBUS write drivers
  input  logic        io_load,            // Load CBUS register from external CBUS
  input  logic        io_read_select,     // Select low/high word for I/O read
  input  logic        io_write_select,    // Select I/O write mode
  input  logic        dma_imem_select,    // DMA target is IMEM (vs DMEM)
  input  logic        dma_dm_to_rd,       // DMA read from memory to RDP
  input  logic        dma_rd_to_dm,       // DMA write from RDP to memory
  input  logic [11:3] dma_address,        // DMA address bus
  input  logic [ 1:0] dma_mask,           // 32-bit word write enable mask
  input  logic        mem_load,           // Load CBUS register from memory

  // Memory Data Interfaces
  input  logic [31:0] im_to_rd_data,      // Data from IMEM
  input  logic [31:0] dmem_rd_data,       // Data from DMEM

  // Program Counter
  input  logic [11:2] pc,                 // Program counter
  input  logic        imem_dma_cycle,     // IMEM DMA cycle active

  // External Buses (Bidirectional)
  inout  tri   [31:0] cbus_data,          // Control/data bus
  inout  tri   [31:0] dbus_data,          // DMA data bus

  // Outputs to Memory and System
  output logic        ex_dma_rd_to_dm,    // DMA write enable
  output logic        ex_dma_dm_to_rd,    // DMA read enable
  output logic [31:0] mem_write_data,     // Write data to memory
  output logic [31:0] imem_datain,        // Data input to IMEM
  output logic [ 3:0] dma_wen,            // DMA write enable per byte

  // IMEM Control Outputs
  output logic [11:3] imem_addr,          // IMEM address
  output logic        imem_web,           // IMEM write enable (active low)
  output logic        imem_csb,           // IMEM chip select (active low)

  // Debug
  output logic [11:0] debug_pc            // Debug program counter output
);

  /*********************************************************************
    Internal Registers and Signals
   *********************************************************************/

  // Reset synchronization
  logic    rst_n_lat;

  // IMEM to CBUS pipeline stages
  logic        im_to_rd_pre_pre_if;  // Two stages before IF
  logic        im_to_rd_pre_if;      // One stage before IF
  logic        im_to_rd_if;          // IF stage
  logic        im_to_rd_rd;          // RD stage (final)

  // CBUS to IMEM pipeline stages
  logic        rd_to_im_pre_pre_if;  // Two stages before IF
  logic        rd_to_im_pre_if;      // One stage before IF
  logic        rd_to_im_if;          // IF stage

  // DMA control pipeline
  logic [11:3] imem_dma_address;     // Pipelined DMA address
  logic [ 1:0] dma_mask_pl;          // Pipelined DMA mask
  logic        dma_rd_to_dm_d;       // DMEM write enable (delayed)
  logic        dma_dm_to_rd_d;       // DMEM read enable (delayed)

  // Data path registers
  logic [63:0] next_dbus_data;
  logic [63:0] dbus_data_reg;
  logic [63:0] mem_read_data;
  logic [63:0] mem_write_data_delayed;
  logic [63:0] rd_to_im_data;

  // CBUS data path
  logic [31:0] io_read_data;
  logic [31:0] mem_load_data;
  logic [31:0] io_write_data;
  logic [31:0] next_cbus_data;
  logic [31:0] cbus_data_reg;

  // Reset latch
  always_ff @(posedge clk)
    rst_n_lat <= rst_n;

  /*********************************************************************
    IMEM to CBUS Pipeline
   *********************************************************************/

  // Generate pipeline enable signal
  assign im_to_rd_pre_pre_if = dma_dm_to_rd && dma_imem_select;

  // Pipeline: 2 cycles before IF - RD
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      im_to_rd_pre_if <= '0;
      im_to_rd_if     <= '0;
      im_to_rd_rd     <= '0;
    end
    else begin
      im_to_rd_pre_if <= im_to_rd_pre_pre_if;
      im_to_rd_if     <= im_to_rd_pre_if;
      im_to_rd_rd     <= im_to_rd_if;
    end
  end

  /*********************************************************************
    DMA Write Enable Generation
   *********************************************************************/

  // DMA mask latch
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) dma_mask_pl <= '0;
    else        dma_mask_pl <= dma_mask;

  // Generate byte-wise write enables
  assign dma_wen = {4{ex_dma_rd_to_dm}} & {dma_mask_pl, dma_mask};

  /*********************************************************************
    DMEM DMA Control Pipeline
   *********************************************************************/

  // Filter DMA signals for DMEM only
  assign dma_rd_to_dm_d = dma_rd_to_dm && !dma_imem_select;
  assign dma_dm_to_rd_d = dma_dm_to_rd && !dma_imem_select;

  // Register signals
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_dma_rd_to_dm <= '0;
      ex_dma_dm_to_rd <= '0;
    end
    else begin
      ex_dma_rd_to_dm <= dma_rd_to_dm_d;
      ex_dma_dm_to_rd <= dma_dm_to_rd_d;
    end
  end

  /*********************************************************************
    CBUS to IMEM Pipeline
   *********************************************************************/

  // Generate pipeline enable signal
  assign rd_to_im_pre_pre_if = dma_rd_to_dm && dma_imem_select;

  // Pipeline: 2 cycles before IF - IF
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_to_im_pre_if <= '0;
      rd_to_im_if     <= '0;
    end
    else begin
      rd_to_im_pre_if <= rd_to_im_pre_pre_if;
      rd_to_im_if     <= rd_to_im_pre_if;
    end
  end

  // Delay write data for timing
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) mem_write_data_delayed <= '0;
    else        mem_write_data_delayed <= mem_write_data;

  // Capture write data when needed
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)               rd_to_im_data <= '0;
    else if (rd_to_im_pre_if) rd_to_im_data <= mem_write_data_delayed;

  // DMA address latch
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) imem_dma_address <= '0;
    else    imem_dma_address <= dma_address;

  // IMEM address mux: PC during normal operation, DMA address during DMA
  assign imem_addr = imem_dma_cycle ? imem_dma_address : pc[11:3];

  assign imem_datain = rd_to_im_data;

  assign imem_web = !(rd_to_im_if || !rst_n_lat);

  // Always enabled
  assign imem_csb = '0;

  /*********************************************************************
    DBUS Interface
   *********************************************************************/

  // Select memory read source
  assign mem_read_data = im_to_rd_rd ? im_to_rd_data : dmem_rd_data;

  // Mux between external DBUS and internal memory data
  assign next_dbus_data = dbus_read_enable ? dbus_data : mem_read_data;

  // DBUS data latch
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) dbus_data_reg <= '0;
    else    dbus_data_reg <= next_dbus_data;

  // Tri-state control for DBUS output
  assign dbus_data = dbus_write_enable ? dbus_data_reg : 'z;

  /*********************************************************************
    CBUS Interface
   *********************************************************************/

  // Select high or low word from memory data
  assign io_read_data = io_read_select ? mem_read_data[31:0] : mem_read_data[63:32];

  // Select between memory and CBUS register
  assign mem_load_data = mem_load ? io_read_data : cbus_data_reg;

  // Select data source for CBUS register
  assign next_cbus_data = io_load ? cbus_data : mem_load_data;

  // CBUS data latch
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) cbus_data_reg <= '0;
    else    cbus_data_reg <= next_cbus_data;

  // Tri-state control for CBUS output
  assign cbus_data = cbus_write_enable ? cbus_data_reg : 'z;

  /*********************************************************************
    Memory Write Datapath
   *********************************************************************/

  // Construct write data based on I/O select
  assign io_write_data = io_read_select ? {mem_read_data[63:32], cbus_data_reg}
                                        : {cbus_data_reg, mem_read_data[31:0]};

  // Select between I/O write and DBUS data
  assign mem_write_data   = io_write_select ? io_write_data : dbus_data_reg;

  /*********************************************************************
    Debug Output
   *********************************************************************/

  assign debug_pc = {imem_addr, 3'b000};

endmodule: busses
