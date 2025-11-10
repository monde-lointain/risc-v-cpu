////////////////////////////////////////////////////////////////////////////////
// Module: rspbusses
// Description: Interface controller between IMEM/DMEM and external buses
//              Manages DMA transactions, CBUS/DBUS interfaces, and BIST control
//
// Refactored: Enhanced for readability and maintainability
////////////////////////////////////////////////////////////////////////////////

module rspbusses (
    // Clock and Reset
    input  logic        clk,
    input  logic        rst_n,          // Active-low reset
    input  logic        iddq_test,      // IDDQ test mode
    
    // DMA Control Signals
    input  logic        cbus_write_enable,      // Enable CBUS write
    input  logic        dbus_read_enable,       // Enable DBUS read
    input  logic        dbus_write_enable,      // Enable DBUS write drivers
    input  logic        io_load,                // Load CBUS register from external CBUS
    input  logic        io_read_select,         // Select low/high word for I/O read
    input  logic        io_write_select,        // Select I/O write mode
    input  logic        dma_imem_select,        // DMA target is IMEM (vs DMEM)
    input  logic        dma_dm_to_rd,           // DMA read from memory to RDP
    input  logic        dma_rd_to_dm,           // DMA write from RDP to memory
    input  logic [11:3] dma_address,            // DMA address bus
    input  logic [1:0]  dma_mask,               // 32-bit word write enable mask
    input  logic        mem_load,               // Load CBUS register from memory
    
    // Memory Data Interfaces
    input  logic [63:0] im_to_rd_data,          // Data from IMEM
    input  logic [63:0] dmem_rd_data,           // Data from DMEM
    
    // Program Counter
    input  logic [11:2] pc,                     // Program counter
    input  logic        imem_dma_cycle,         // IMEM DMA cycle active
    
    // External Buses
    inout  tri   [31:0] cbus_data,              // Control/data bus
    inout  tri   [63:0] dbus_data,              // DMA data bus
    
    // Outputs to Memory and System
    output logic        dma_write_enable,       // DMA write enable
    output logic        dma_read_enable,        // DMA read enable
    output logic [63:0] mem_write_data,         // Write data to memory
    output logic [63:0] imem_datain,            // Data input to IMEM
    output logic [3:0]  dma_wen,                // DMA write enable per byte
    
    // IMEM Control Outputs
    output logic [11:3] final_pc,               // Final program counter to IMEM
    output logic        imem_web,               // IMEM write enable (active low)
    output logic        imem_csb,               // IMEM chip select (active low)
    
    // Debug
    output logic [11:0] debug_pc                // Debug program counter output
);

    //==========================================================================
    // Internal Registers and Signals
    //==========================================================================
    
    // Reset synchronization
    logic        rst_n_lat;
    
    // IMEM to RDP pipeline stages
    logic        im_to_rd_pre_pre_if;           // Two stages before IF
    logic        im_to_rd_pre_if;               // One stage before IF
    logic        im_to_rd_if;                   // IF stage
    logic        im_to_rd_rd;                   // RD stage (final)
    
    // RDP to IMEM pipeline stages  
    logic        rd_to_im_pre_pre_if;           // Two stages before IF
    logic        rd_to_im_pre_if;               // One stage before IF
    logic        rd_to_im_if;                   // IF stage
    
    // DMA control pipeline
    logic [11:3] imem_dma_address;              // Pipelined DMA address
    logic [1:0]  dma_mask_pl;                   // Pipelined DMA mask
    logic        dma_rd_to_dm_d;                // DMEM write enable (delayed)
    logic        dma_dm_to_rd_d;                // DMEM read enable (delayed)
    
    // Data path registers
    logic [63:0] next_dbus_data;
    logic [63:0] dbus_data_reg;
    logic [63:0] mem_read_data;
    logic [63:0] mem_write_data_tmp;
    logic [63:0] mem_write_data_delayed;
    logic [63:0] rd_to_im_data;
    
    // CBUS data path
    logic [31:0] io_read_data;
    logic [31:0] mem_load_data;
    logic [31:0] io_write_data;
    logic [31:0] next_cbus_data;
    logic [31:0] cbus_data_reg;
    
    //==========================================================================
    // Reset Synchronization
    //==========================================================================
    
    always_ff @(posedge clk) begin
        rst_n_lat <= rst_n;
    end
    
    /*******************************************************************
       IMEM Datapath Pipeline
     *******************************************************************/
    
    // Generate pipeline enable signal
    assign im_to_rd_pre_pre_if = dma_dm_to_rd && dma_imem_select;
    
    // Pipeline stage 1: Two cycles before IF
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            im_to_rd_pre_if <= 1'b0;
        end
        else begin
            im_to_rd_pre_if <= im_to_rd_pre_pre_if;
        end
    end
    
    // Pipeline stage 2: One cycle before IF
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            im_to_rd_if <= 1'b0;
        end
        else begin
            im_to_rd_if <= im_to_rd_pre_if;
        end
    end
    
    // Pipeline stage 3: Read data stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            im_to_rd_rd <= 1'b0;
        end
        else begin
            im_to_rd_rd <= im_to_rd_if;
        end
    end
    
    //==========================================================================
    // DMA Write Enable Generation
    //==========================================================================
    
    // Pipeline DMA mask
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_mask_pl <= 2'b00;
        end
        else begin
            dma_mask_pl <= dma_mask;
        end
    end
    
    // Generate byte-wise write enables
    assign dma_wen = {4{dma_write_enable}} & {dma_mask_pl, dma_mask};
    
    //==========================================================================
    // DMEM DMA Control Pipeline
    //==========================================================================
    
    // Filter DMA signals for DMEM only
    assign dma_rd_to_dm_d = dma_rd_to_dm && !dma_imem_select;
    assign dma_dm_to_rd_d = dma_dm_to_rd && !dma_imem_select;
    
    // Pipeline DMA write enable
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_write_enable <= 1'b0;
        end
        else begin
            dma_write_enable <= dma_rd_to_dm_d;
        end
    end
    
    // Pipeline DMA read enable
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_read_enable <= 1'b0;
        end
        else begin
            dma_read_enable <= dma_dm_to_rd_d;
        end
    end
    
    //==========================================================================
    // XBUS Output Mux
    //==========================================================================
    
    // Select between DMEM data and DBUS register
    assign xbus_data = xbus_dmem_select ? dmem_rd_data : dbus_data_reg;
    
    //==========================================================================
    // RDP to IMEM Write Path Pipeline
    //==========================================================================
    
    // Generate pipeline enable signal
    assign rd_to_im_pre_pre_if = dma_rd_to_dm && dma_imem_select;
    
    // Pipeline stage 1: Two cycles before IF
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_to_im_pre_if <= 1'b0;
        end
        else begin
            rd_to_im_pre_if <= rd_to_im_pre_pre_if;
        end
    end
    
    // Pipeline stage 2: IF stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_to_im_if <= 1'b0;
        end
        else begin
            rd_to_im_if <= rd_to_im_pre_if;
        end
    end
    
    // Delay write data for timing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_write_data_delayed <= 64'h0;
        end
        else begin
            mem_write_data_delayed <= mem_write_data;
        end
    end
    
    // Capture write data when needed
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_to_im_data <= 64'h0;
        end
        else if (rd_to_im_pre_if) begin
            rd_to_im_data <= mem_write_data_delayed;
        end
    end
    
    // Pipeline DMA address
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            imem_dma_address <= 9'h0;
        end
        else begin
            imem_dma_address <= dma_address;
        end
    end

    assign imem_datain = imem_write_data;
    
    // IMEM write enable (active low)
    assign imem_web = !dma_write_imem;
    
    // IMEM chip select (active low) - always enabled
    assign imem_csb = 1'b0;
    
    //==========================================================================
    // DBUS Interface
    //==========================================================================
    
    // Select memory read source
    assign mem_read_data = im_to_rd_rd ? im_to_rd_data : dmem_rd_data;
    
    // Mux between external DBUS and internal memory data
    assign next_dbus_data = dbus_read_enable ? dbus_data : mem_read_data;
    
    // Register DBUS data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbus_data_reg <= 64'h0;
        end
        else begin
            dbus_data_reg <= next_dbus_data;
        end
    end
    
    // Tri-state control for DBUS output
    assign dbus_data = dbus_write_enable ? dbus_data_reg : 64'hzzzzzzzzzzzzzzzz;
    
    //==========================================================================
    // CBUS Interface
    //==========================================================================
    
    // Select high or low word from memory data
    assign io_read_data = io_read_select ? mem_read_data[31:0] : mem_read_data[63:32];
    
    // Select between memory and CBUS register
    assign mem_load_data = mem_load ? io_read_data : cbus_data_reg;
    
    // Select data source for CBUS register
    assign next_cbus_data = io_load ? cbus_data : mem_load_data;
    
    // Register CBUS data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cbus_data_reg <= 32'h0;
        end
        else begin
            cbus_data_reg <= next_cbus_data;
        end
    end
    
    // Tri-state control for CBUS output
    assign cbus_data = cbus_write_enable ? cbus_data_reg : 32'hzzzzzzzz;
    
    //==========================================================================
    // Memory Write Data Path
    //==========================================================================
    
    // Construct write data based on I/O select
    assign io_write_data = io_read_select ? {mem_read_data[63:32], cbus_data_reg}
                                          : {cbus_data_reg, mem_read_data[31:0]};
    
    // Select between I/O write and DBUS data
    assign mem_write_data_tmp = io_write_select ? io_write_data : dbus_data_reg;
    assign mem_write_data     = mem_write_data_tmp;
    
    //==========================================================================
    // Debug Output
    //==========================================================================
    
    assign debug_pc = {final_pc, 3'b000};
    
endmodule : rspbusses
