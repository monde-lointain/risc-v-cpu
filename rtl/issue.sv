// ==============================================================================
// Module: issue
// Description: Instruction issue logic for single-issue RISC-V processor.
//              Handles PC generation, branch resolution, and instruction
//              stalling. No branch delay slots - branches resolved immediately.
// ==============================================================================

module issue (
  // Clock and Reset
  input  logic        clk, rst_n,
  
  // Control Inputs
  input  logic        halt,
  input  logic        single_step,
  input  logic        id_adv,
  input  logic        ex_kill,
  
  // PC Control
  input  logic        pc_in_wr_en,
  input  logic [31:0] pc_data_in,
  
  // Branch Control
  input  logic        taken,
  input  logic [31:0] br_addr,
  
  // Instruction Memory Interface
  input  logic [31:0] id_inst,
  input  logic        imem_dma_pif,
  
  // Outputs
  output logic [31:0] inst,
  output logic        nop_debug,
  output logic [31:0] pc,
  output logic        kill_issue
);

  // ==========================================================================
  // Internal Signal Declarations
  // ==========================================================================
  
  // PC Management
  logic [31:0] next_pc;
  logic        pc_wr_en;
  logic        adv_pc;
  
  // Instruction Stalling
  logic        should_stall;
  logic        prev_stalled;
  logic        save_id_inst;
  logic [31:0] stalled_id_inst;
  logic [31:0] muxed_id_inst;
  logic        imem_dma_if;
  logic        imem_stall;
  
  // Issue Control
  logic        kill_issue_pre;
  
  // ==========================================================================
  // PC Generation and Management
  // ==========================================================================
  
  // PC Selection Logic
  always_comb begin
    if (pc_in_wr_en) begin
      // External write (highest priority)
      next_pc = pc_data_in;
    end else if (taken) begin
      // Branch taken - use branch target
      next_pc = br_addr;
    end else if (!halt && !imem_dma_if) begin
      // Sequential execution - PC + 4
      next_pc = pc + 32'd4;
    end else begin
      // Hold PC (halted or DMA)
      next_pc = pc;
    end
  end
  
  // PC Write Enable
  assign pc_wr_en = pc_in_wr_en || adv_pc;
  
  // Advance PC when not stalled
  assign adv_pc = id_adv && !should_stall && !halt && !imem_dma_if;
  
  // PC Register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      pc <= 32'h0;
    else if (pc_wr_en)
      pc <= next_pc;
  end
  
  // ==========================================================================
  // Instruction Stalling Management
  // ==========================================================================
  
  // DMA interface tracking
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      imem_dma_if <= 1'b0;
    else
      imem_dma_if <= imem_dma_pif;
  end
  
  // Stall detection
  assign should_stall = imem_stall || imem_dma_if;
  
  // Track previous stall state
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      prev_stalled <= 1'b0;
    else
      prev_stalled <= should_stall;
  end
  
  // Save instruction on first cycle of stall
  assign save_id_inst = should_stall && !prev_stalled;
  
  always_ff @(posedge clk) begin
    if (save_id_inst)
      stalled_id_inst <= id_inst;
  end
  
  // Use saved instruction if we were stalled
  assign muxed_id_inst = prev_stalled ? stalled_id_inst : id_inst;
  
  // ==========================================================================
  // Instruction Issue Control
  // ==========================================================================
  
  // Kill instruction issue on:
  // - Pipeline flush (branch taken)
  // - External kill signal
  // - Halt condition
  // - DMA access
  assign kill_issue_pre = taken || halt || imem_dma_if;
  
  // Apply single-step if enabled
  assign kill_issue = kill_issue_pre || (single_step && id_adv) || ex_kill;
  
  // Output instruction (NOP if killed)
  assign inst = kill_issue ? 32'h00000013 : muxed_id_inst;  // RISC-V NOP = ADDI x0, x0, 0
  
  assign nop_debug = kill_issue;
  
  // ==========================================================================
  // IMem Stall Logic
  // ==========================================================================
  
  // Simple stall logic - can be extended for load-use hazards, etc.
  assign imem_stall = 1'b0;  // Placeholder - implement based on pipeline requirements

endmodule: issue


// ==============================================================================
// Module: hazard_unit
// Description: Detects data hazards between instructions in the pipeline
//              For RISC-V single-issue processor with forwarding
// ==============================================================================

module hazard_unit (
  input  logic [31:0] decode_inst,
  input  logic [31:0] execute_inst,
  input  logic [31:0] memory_inst,
  input  logic        execute_reg_write,
  input  logic        memory_reg_write,
  input  logic        memory_is_load,
  output logic        stall_decode,
  output logic        flush_decode
);

  // ==========================================================================
  // Register Field Extraction
  // ==========================================================================
  
  // Decode stage
  logic [4:0] decode_rs1, decode_rs2, decode_rd;
  logic [6:0] decode_opcode;
  
  assign decode_opcode = decode_inst[6:0];
  assign decode_rs1    = decode_inst[19:15];
  assign decode_rs2    = decode_inst[24:20];
  assign decode_rd     = decode_inst[11:7];
  
  // Execute stage
  logic [4:0] execute_rd;
  assign execute_rd = execute_inst[11:7];
  
  // Memory stage
  logic [4:0] memory_rd;
  assign memory_rd = memory_inst[11:7];
  
  // ==========================================================================
  // Hazard Detection
  // ==========================================================================
  
  logic load_use_hazard;
  logic decode_uses_rs1, decode_uses_rs2;
  
  // Determine if decode instruction uses rs1/rs2
  always_comb begin
    case (decode_opcode)
      7'b0110011: begin  // R-type
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b1;
      end
      7'b0010011: begin  // I-type (immediate)
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b0;
      end
      7'b0000011: begin  // Load
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b0;
      end
      7'b0100011: begin  // Store
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b1;
      end
      7'b1100011: begin  // Branch
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b1;
      end
      7'b1100111: begin  // JALR
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b0;
      end
      default: begin
        decode_uses_rs1 = 1'b0;
        decode_uses_rs2 = 1'b0;
      end
    endcase
  end
  
  // Load-use hazard: instruction in execute is a load and current instruction
  // needs the result
  assign load_use_hazard = memory_is_load && (
    (decode_uses_rs1 && (execute_rd == decode_rs1) && (execute_rd != 5'b0)) ||
    (decode_uses_rs2 && (execute_rd == decode_rs2) && (execute_rd != 5'b0))
  );
  
  // Stall if load-use hazard detected
  assign stall_decode = load_use_hazard;
  
  // Flush on branch mispredict (handled externally)
  assign flush_decode = 1'b0;

endmodule: hazard_unit


// ==============================================================================
// Module: forwarding_unit
// Description: Handles data forwarding to resolve RAW hazards without stalling
// ==============================================================================

module forwarding_unit (
  input  logic [4:0]  execute_rs1,
  input  logic [4:0]  execute_rs2,
  input  logic [4:0]  memory_rd,
  input  logic [4:0]  writeback_rd,
  input  logic        memory_reg_write,
  input  logic        writeback_reg_write,
  output logic [1:0]  forward_a,  // 00: no forward, 01: from memory, 10: from writeback
  output logic [1:0]  forward_b
);

  // Forward to rs1 (operand A)
  always_comb begin
    if (memory_reg_write && (memory_rd != 5'b0) && (memory_rd == execute_rs1)) begin
      forward_a = 2'b01;  // Forward from memory stage
    end else if (writeback_reg_write && (writeback_rd != 5'b0) && (writeback_rd == execute_rs1)) begin
      forward_a = 2'b10;  // Forward from writeback stage
    end else begin
      forward_a = 2'b00;  // No forwarding
    end
  end
  
  // Forward to rs2 (operand B)
  always_comb begin
    if (memory_reg_write && (memory_rd != 5'b0) && (memory_rd == execute_rs2)) begin
      forward_b = 2'b01;  // Forward from memory stage
    end else if (writeback_reg_write && (writeback_rd != 5'b0) && (writeback_rd == execute_rs2)) begin
      forward_b = 2'b10;  // Forward from writeback stage
    end else begin
      forward_b = 2'b00;  // No forwarding
    end
  end

endmodule: forwarding_unit
