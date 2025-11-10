// ==============================================================================
// Module: control
// Description: Control unit with integrated issue logic, hazard detection, 
//              and forwarding.
// ==============================================================================

module control
import definitions_pkg::*;
(
  // Clock and Reset
  input  logic        clk, rst_n,
  
  // Control Inputs
  input  logic        halt,
  input  logic        single_step,
  input  logic [31:0] inst,
  
  // DMA Signals
  input  logic        dma_dm_to_id,
  input  logic        dma_id_to_dm,
  input  logic        dma_imem_select,
  
  // Branch Resolution
  input  logic        br_eq, br_lt,
  
  // PC Control
  input  logic        pc_in_wr_en,
  input  logic [31:0] pc_data_in,
  
  // Outputs - Control Signals
  output logic        imem_dma_pif,
  output logic        id_adv,
  output logic        ex_kill,
  output logic        taken,
  output logic        kill_issue,
  output logic        nop_debug,
  
  // Outputs - PC
  output logic [31:0] pc,
  output logic [31:0] br_addr,
  
  // Outputs - Register File
  output logic [ 4:0] rf_ra, rf_rb, rf_w,
  output logic        rf_wen,
  
  // Outputs - Pipeline Control
  output logic [ 1:0] wb_sel,
  output logic [ 1:0] ex_a_sel, ex_b_sel,
  output imm_e        imm_sel,
  output logic        alu_a_sel,
  output alu_e        alu_op,
  output logic        br_uns,
  
  // Outputs - Memory Operations
  output logic        ex_load, ex_store,
  output logic        ex_byte_ls, ex_half_ls, ex_uns_ls
);

  // ==========================================================================
  // RISC-V Opcode Definitions
  // ==========================================================================
  localparam logic [6:0]
    OPCODE_LOAD    = 7'b0000011,
    OPCODE_STORE   = 7'b0100011,
    OPCODE_BRANCH  = 7'b1100011,
    OPCODE_JALR    = 7'b1100111,
    OPCODE_JAL     = 7'b1101111,
    OPCODE_OP_IMM  = 7'b0010011,
    OPCODE_OP      = 7'b0110011,
    OPCODE_SYSTEM  = 7'b1110011,
    OPCODE_AUIPC   = 7'b0010111,
    OPCODE_LUI     = 7'b0110111;

  // ==========================================================================
  // Instruction Field Extraction
  // ==========================================================================
  logic [6:0] opcode;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [4:0] rs1, rs2, rd;
  
  assign opcode = inst[6:0];
  assign funct7 = inst[31:25];
  assign funct3 = inst[14:12];
  assign rs1    = inst[19:15];
  assign rs2    = inst[24:20];
  assign rd     = inst[11:7];

  // ==========================================================================
  // Pipeline Stage Registers
  // ==========================================================================
  
  // ID Stage Signals
  logic       id_wr_en, id_wr_en_k;
  logic       id_imm, id_br_uns;
  logic       id_jump, id_jump_k;
  logic       id_a_gets_npc, id_a_gets_npc_k;
  logic       id_load, id_load_k;
  logic       id_store, id_store_k;
  logic       id_byte_ls, id_byte_ls_k;
  logic       id_half_ls, id_half_ls_k;
  logic       id_uns_ls, id_uns_ls_k;
  logic       use_a, use_b, a_gets0;
  alu_e       id_alu_op;
  branch_e    id_br_type, id_br_type_k;
  logic [4:0] id_wr_reg;
  
  // EX Stage Registers
  logic [4:0] ex_wr_reg;
  logic       ex_wr_en;
  logic       ex_a_gets_npc;
  branch_e    ex_br_type;
  logic       ex_jump;
  logic       ex_dma_cycle;
  
  // MEM Stage Registers
  logic [4:0] mem_wr_reg;
  logic       mem_wr_en;
  logic       mem_load;
  logic       mem_jump;
  logic       mem_dma_cycle;
  
  // WB Stage Registers
  logic [4:0] wb_wr_reg;
  logic       wb_wr_en;
  logic       wb_load;
  logic       wb_jump;

  // ==========================================================================
  // PC Management
  // ==========================================================================
  logic [31:0] next_pc;
  logic        pc_wr_en, advance_pc;
  logic        prev_halt;
  logic        imem_dma_ppif, imem_dma_if, imem_dma_id;
  
  always_comb
    if (pc_in_wr_en)                next_pc = pc_data_in;  // External write
    else if (taken)                 next_pc = br_addr;     // Branch target
    else if (!halt && !imem_dma_if) next_pc = pc + 32'd4;  // PC + 4
    else                            next_pc = pc;          // Hold
  
  assign pc_wr_en   = pc_in_wr_en || advance_pc;
  assign advance_pc = id_adv && !halt && !imem_dma_if;
  
  // PC Latch
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)        pc <= '0;
    else if (pc_wr_en) pc <= next_pc;

  // ==========================================================================
  // Instruction Decode
  // ==========================================================================
  assign rf_ra     = rs1;
  assign rf_rb     = rs2;
  assign id_wr_reg = rd;

  always_comb begin
    // Default values
    imm_sel       = IMM_XXX;
    id_wr_en      = '1;
    use_a         = '1;
    use_b         = '0;
    a_gets0       = '0;
    id_alu_op     = ALU_XXX;
    id_imm        = '1;
    id_br_type    = BR_XXX;
    id_br_uns     = 'x;
    id_jump       = '0;
    id_a_gets_npc = '0;
    id_load       = '0;
    id_store      = '0;
    id_byte_ls    = 'x;
    id_half_ls    = 'x;
    id_uns_ls     = 'x;

    case (opcode)
      OPCODE_LUI: begin
        imm_sel   = IMM_U_TYPE;
        use_a     = '0;
        a_gets0   = '1;
        id_alu_op = ALU_OR; // OR ALU B with 0
      end
      OPCODE_AUIPC: begin
        imm_sel       = IMM_U_TYPE;
        use_a         = '0;
        id_alu_op     = ALU_ADD;
        id_a_gets_npc = '1;
      end
      OPCODE_JAL: begin
        imm_sel       = IMM_JAL;
        id_alu_op     = ALU_ADD;
        id_jump       = '1;
        id_a_gets_npc = '1;
      end
      OPCODE_JALR: begin
        imm_sel   = IMM_I_TYPE;
        id_alu_op = ALU_ADD;
        id_jump   = '1;
      end
      OPCODE_BRANCH: begin
        imm_sel       = IMM_BRANCH;
        id_wr_en      = '0;
        use_b         = '1;
        id_alu_op     = ALU_ADD;
        id_a_gets_npc = '1;

        case (funct3)
          3'b000:  {id_br_type, id_br_uns} = {BR_EQ, '0}; // BEQ
          3'b001:  {id_br_type, id_br_uns} = {BR_NE, '0}; // BNE
          3'b100:  {id_br_type, id_br_uns} = {BR_LT, '0}; // BLT
          3'b101:  {id_br_type, id_br_uns} = {BR_GE, '0}; // BGE
          3'b110:  {id_br_type, id_br_uns} = {BR_LT, '1}; // BLTU
          3'b111:  {id_br_type, id_br_uns} = {BR_GE, '1}; // BGEU
          default: {id_br_type, id_br_uns} = {BR_XXX, 'x};
        endcase
      end
      OPCODE_LOAD: begin
        imm_sel   = IMM_I_TYPE;
        id_alu_op = ALU_ADD;
        id_load   = '1;

        case (funct3)
          3'b000:  {id_byte_ls, id_half_ls, id_uns_ls} = 3'b100; // LB
          3'b001:  {id_byte_ls, id_half_ls, id_uns_ls} = 3'b010; // LH
          3'b010:  {id_byte_ls, id_half_ls, id_uns_ls} = 3'b000; // LW
          3'b100:  {id_byte_ls, id_half_ls, id_uns_ls} = 3'b101; // LBU
          3'b101:  {id_byte_ls, id_half_ls, id_uns_ls} = 3'b011; // LHU
          default: {id_byte_ls, id_half_ls, id_uns_ls} = 3'b000;
        endcase
      end
      OPCODE_STORE: begin
        imm_sel   = IMM_STORE;
        id_wr_en  = '0;
        use_b     = '1;
        id_alu_op = ALU_ADD;
        id_store  = '1;
        
        case (funct3)
          3'b000:  {id_byte_ls, id_half_ls} = 2'b10; // SB
          3'b001:  {id_byte_ls, id_half_ls} = 2'b01; // SH
          3'b010:  {id_byte_ls, id_half_ls} = 2'b00; // SW
          default: {id_byte_ls, id_half_ls} = 2'b00;
        endcase
      end
      OPCODE_OP_IMM: begin
        imm_sel = IMM_I_TYPE;
        
        case ({funct7[5], funct3})
          4'b0_000: id_alu_op = ALU_ADD;  // ADDI
          4'b0_010: id_alu_op = ALU_SLT;  // SLTI
          4'b0_011: id_alu_op = ALU_SLTU; // SLTIU
          4'b0_100: id_alu_op = ALU_XOR;  // XORI
          4'b0_110: id_alu_op = ALU_OR;   // ORI
          4'b0_111: id_alu_op = ALU_AND;  // ANDI
          4'b0_001: id_alu_op = ALU_SLL;  // SLLI
          4'b0_101: id_alu_op = ALU_SRL;  // SRLI
          4'b1_101: id_alu_op = ALU_SRA;  // SRAI
          default:  id_alu_op = ALU_XXX;
        endcase
      end
      OPCODE_OP: begin
        use_b  = '1;
        id_imm = '0;
        
        case ({funct7[5], funct3})
          4'b0_000: id_alu_op = ALU_ADD;  // ADD
          4'b1_000: id_alu_op = ALU_SUB;  // SUB
          4'b0_001: id_alu_op = ALU_SLL;  // SLL
          4'b0_010: id_alu_op = ALU_SLT;  // SLT
          4'b0_011: id_alu_op = ALU_SLTU; // SLTU
          4'b0_100: id_alu_op = ALU_XOR;  // XOR
          4'b0_101: id_alu_op = ALU_SRL;  // SRL
          4'b1_101: id_alu_op = ALU_SRA;  // SRA
          4'b0_110: id_alu_op = ALU_OR;   // OR
          4'b0_111: id_alu_op = ALU_AND;  // AND
          default:  id_alu_op = ALU_XXX;
        endcase
      end
      default: begin
        // Invalid instruction - propagate X's for debugging
        {id_wr_en, use_a, use_b, a_gets0} = 4'bxxxx;
        {id_imm, id_br_uns, id_jump, id_a_gets_npc} = 4'bxxxx;
        {id_load, id_store, id_byte_ls, id_half_ls, id_uns_ls} = 5'bxxxxx;
      end
    endcase
  end

  // ==========================================================================
  // Hazard Detection & Pipeline Control
  // ==========================================================================
  logic load_use_stall, load_store_stall, dmem_dma_stall;
  logic id_dma_cycle;
  logic a_ex_byp, a_mem_byp, a_wb_byp;
  logic b_ex_byp, b_mem_byp, b_wb_byp;
  
  // Bypass detection
  assign a_ex_byp = ({rs1, '1} == {ex_wr_reg, ex_wr_en});
  assign a_mem_byp = ({rs1, '1} == {mem_wr_reg, mem_wr_en});
  assign a_wb_byp = ({rs1, '1} == {wb_wr_reg, wb_wr_en});
  
  assign b_ex_byp = ({rs2, '1} == {ex_wr_reg, ex_wr_en});
  assign b_mem_byp = ({rs2, '1} == {mem_wr_reg, mem_wr_en});
  assign b_wb_byp = ({rs2, '1} == {wb_wr_reg, wb_wr_en});
  
  // Stall conditions
  assign load_use_stall = 
      (use_a && a_ex_byp && ex_load) || 
      (use_a && a_mem_byp && mem_load) || 
      (use_b && b_ex_byp && ex_load) || 
      (use_b && b_mem_byp && mem_load);
  assign load_store_stall = id_store && mem_load;
  
  assign id_dma_cycle   = (dma_dm_to_id || dma_id_to_dm) && !dma_imem_select;
  assign dmem_dma_stall = (id_dma_cycle || mem_dma_cycle) && (id_store || id_load);
  
  assign id_adv  = !(load_use_stall || load_store_stall || dmem_dma_stall);
  assign ex_kill = imem_dma_id || halt || prev_halt || !id_adv;
  
  // Killed instruction signals
  assign id_store_k      = id_store && !ex_kill;
  assign id_load_k       = id_load && !ex_kill;
  assign id_wr_en_k      = id_wr_en && !ex_kill;
  assign id_br_type_k    = branch_e'(id_br_type & {4{!ex_kill}});
  assign id_jump_k       = id_jump && !ex_kill;
  assign id_a_gets_npc_k = id_a_gets_npc && !ex_kill;
  assign id_byte_ls_k    = id_byte_ls && !ex_kill;
  assign id_half_ls_k    = id_half_ls && !ex_kill;
  assign id_uns_ls_k     = id_uns_ls && !ex_kill;

  // ==========================================================================
  // Operand Forwarding Multiplexers
  // ==========================================================================
  always_comb
    unique case (1'b1)
      a_gets0:   ex_a_sel = 2'b11; // LUI (a = 0)
      a_wb_byp:  ex_a_sel = 2'b10; // WB bypass
      a_mem_byp: ex_a_sel = 2'b01; // MEM bypass
      default:   ex_a_sel = 2'b00; // rs1
    endcase

  always_comb
    unique case (1'b1)
      id_imm:    ex_b_sel = 2'b11; // Immediate
      b_wb_byp:  ex_b_sel = 2'b10; // WB bypass
      b_mem_byp: ex_b_sel = 2'b01; // MEM bypass
      default:   ex_b_sel = 2'b00; // rs2
    endcase

  // ==========================================================================
  // ID/EX Pipeline Stage
  // ==========================================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      alu_op        <= alu_e'('0);
      br_uns        <= '0;
      ex_store      <= '0;
      ex_load       <= '0;
      ex_wr_reg     <= '0;
      ex_wr_en      <= '0;
      ex_br_type    <= branch_e'('0);
      ex_jump       <= '0;
      ex_a_gets_npc <= '0;
      ex_byte_ls    <= '0;
      ex_half_ls    <= '0;
      ex_uns_ls     <= '0;
      ex_dma_cycle  <= '0;
    end else begin
      alu_op        <= id_alu_op;
      br_uns        <= id_br_uns;
      ex_store      <= id_store_k;
      ex_load       <= id_load_k;
      ex_wr_reg     <= id_wr_reg;
      ex_wr_en      <= id_wr_en_k;
      ex_br_type    <= id_br_type_k;
      ex_jump       <= id_jump_k;
      ex_a_gets_npc <= id_a_gets_npc_k;
      ex_byte_ls    <= id_byte_ls_k;
      ex_half_ls    <= id_half_ls_k;
      ex_uns_ls     <= id_uns_ls_k;
      ex_dma_cycle  <= id_dma_cycle;
    end
  end

  // ==========================================================================
  // Branch Resolution
  // ==========================================================================
  assign alu_a_sel = ex_a_gets_npc;
  assign taken     = ex_jump ||                    // JAL/R
                     (ex_br_type[0] && br_eq) ||   // BEQ
                     (ex_br_type[1] && !br_eq) ||  // BNE
                     (ex_br_type[2] && br_lt) ||   // BLT/U
                     (ex_br_type[3] && !br_lt);    // BGE/U

  // ==========================================================================
  // EX/MEM Pipeline Stage
  // ==========================================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_dma_cycle <= '0;
      mem_load      <= '0;
      mem_wr_reg    <= 5'd0;
      mem_wr_en     <= '0;
      mem_jump      <= '0;
    end else begin
      mem_dma_cycle <= ex_dma_cycle;
      mem_load      <= ex_load;
      mem_wr_reg    <= ex_wr_reg;
      mem_wr_en     <= ex_wr_en;
      mem_jump      <= ex_jump;
    end
  end

  // ==========================================================================
  // MEM/WB Pipeline Stage
  // ==========================================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wb_load   <= '0;
      wb_wr_reg <= '0;
      wb_wr_en  <= '0;
      wb_jump   <= '0;
    end else begin
      wb_load   <= mem_load;
      wb_wr_reg <= mem_wr_reg;
      wb_wr_en  <= mem_wr_en;
      wb_jump   <= mem_jump;
    end
  end

  // ==========================================================================
  // Writeback Control
  // ==========================================================================
  assign rf_w   = wb_wr_reg;
  assign rf_wen = wb_wr_en;
  
  always_comb
    unique case (1'b1)
      wb_load: wb_sel = 2'b00; // Load data
      wb_jump: wb_sel = 2'b10; // PC+4 for JAL/JALR
      default: wb_sel = 2'b01; // ALU result
    endcase 

  // ==========================================================================
  // DMA and Halt Management
  // ==========================================================================
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) prev_halt <= '0;
    else        prev_halt <= halt;

  assign imem_dma_ppif = (dma_dm_to_id || dma_id_to_dm) && dma_imem_select;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      imem_dma_pif <= '0;
      imem_dma_if  <= '0;
      imem_dma_id  <= '0;
    end else begin
      imem_dma_pif <= imem_dma_ppif;
      imem_dma_if  <= imem_dma_pif;
      imem_dma_id  <= imem_dma_if;
    end
  end

  // ==========================================================================
  // Issue Control (Integrated)
  // ==========================================================================
  assign kill_issue = taken || halt || imem_dma_if || (single_step && id_adv) || ex_kill;

endmodule: control
