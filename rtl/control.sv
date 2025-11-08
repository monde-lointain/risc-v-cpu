module control
import definitions_pkg::*;
(input  logic        clk, rst_n,
 input  logic        halt,
 input  logic [31:0] inst,
 input  logic        dma_dm_to_id,
 input  logic        dma_id_to_dm,
 input  logic        dma_imem_select,
 input  logic        br_eq, br_lt,
 output logic        imem_dma_pif,
 output logic        id_adv,
 output logic        ex_kill,
 output logic        taken,
 output logic [ 4:0] rf_ra, rf_rb, rf_w,
 output logic        rf_wen,
 output logic [ 1:0] wb_sel,
 output logic [ 1:0] ex_a_sel, ex_b_sel,
 output imm_e        imm_sel,
 output logic        alu_a_sel,
 output alu_e        alu_op,
 output logic        br_uns,
 output logic        ex_load, ex_store,
 output logic        ex_byte_ls, ex_half_ls,
 output logic        ex_uns_ls
);
  
  localparam OPCODE_LOAD       = 7'b0000011;
  localparam OPCODE_STORE      = 7'b0100011;
  localparam OPCODE_BRANCH     = 7'b1100011;
  localparam OPCODE_JALR       = 7'b1100111;
  localparam OPCODE_JAL        = 7'b1101111;
  localparam OPCODE_OP_IMM     = 7'b0010011;
  localparam OPCODE_OP         = 7'b0110011;
  localparam OPCODE_SYSTEM     = 7'b1110011;
  localparam OPCODE_AUIPC      = 7'b0010111;
  localparam OPCODE_LUI        = 7'b0110111;

  logic       prev_halt;
  logic       imem_dma_ppif;
  logic       imem_dma_if;
  logic       imem_dma_id;
  logic [6:0] opcode;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic       load_use_stall;
  logic       load_store_stall;
  logic       id_dma_cycle;
  logic       ex_dma_cycle;
  logic       mem_dma_cycle;
  logic       dmem_dma_stall;
  logic [4:0] id_wr_reg;
  logic [4:0] ex_wr_reg;
  logic [4:0] mem_wr_reg;
  logic [4:0] wb_wr_reg;
  logic       id_wr_en;
  logic       id_wr_en_k;
  logic       ex_wr_en;
  logic       mem_wr_en;
  logic       wb_wr_en;
  logic       use_a;
  logic       use_b;
  logic       a_gets0;
  logic       a_ex_byp;
  logic       a_mem_byp;
  logic       a_wb_byp;
  logic       b_ex_byp;
  logic       b_mem_byp;
  logic       b_wb_byp;

  alu_e       id_alu_op;
  logic       id_imm;
  branch_e    id_br_type;
  branch_e    id_br_type_k;
  branch_e    ex_br_type;
  logic       id_br_uns;
  logic       id_jump;
  logic       id_jump_k;
  logic       ex_jump;
  logic       mem_jump;
  logic       wb_jump;
  logic       id_a_gets_npc;
  logic       id_a_gets_npc_k;
  logic       ex_a_gets_npc;
  logic       id_load;
  logic       id_load_k;
  logic       mem_load;
  logic       wb_load;

  logic       id_store;
  logic       id_store_k;
  logic       id_byte_ls;
  logic       id_byte_ls_k;
  logic       id_half_ls;
  logic       id_half_ls_k;
  logic       id_uns_ls;
  logic       id_uns_ls_k;

  assign opcode = inst[6:0];
  assign funct7 = inst[31:25];
  assign funct3 = inst[14:12];
  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];

  assign rf_ra = rs1;
  assign rf_rb = rs2;
  assign id_wr_reg = rd;

  // act on opcodes
  always_comb begin
    imm_sel = IMM_XXX;

    id_wr_en = '1;
    use_a = '1;
    use_b = '0;
    a_gets0  = '0;

    id_alu_op = ALU_XXX;
    id_imm = '1;
    id_br_type = BR_XXX;
    id_br_uns = 'x;
    id_jump = '0;
    id_a_gets_npc = '0;
    id_load = '0;

    id_store = '0;
    id_byte_ls = '0;
    id_half_ls = '0;
    id_uns_ls = '0;

    case (opcode)
      // Load Upper Immediate
      OPCODE_LUI: begin
        imm_sel = IMM_U_TYPE;
        use_a = '0;
        a_gets0 = '1;
        id_alu_op = ALU_OR; // OR alu b with 0
      end
      // Add Upper Immediate to Program Counter
      OPCODE_AUIPC: begin
        imm_sel = IMM_U_TYPE;
        use_a = '0;
        id_alu_op = ALU_ADD;
        id_a_gets_npc = '1;
      end
      // Jump And Link (unconditional jump)
      OPCODE_JAL: begin
        imm_sel = IMM_JAL;
        id_alu_op = ALU_ADD;
        id_jump = '1;
        id_a_gets_npc = '1;
      end
      // Jump And Link Register (indirect jump)
      OPCODE_JALR: begin
        imm_sel = IMM_I_TYPE;
        id_alu_op = ALU_ADD;
        id_jump = '1;
      end
      // branch instructions: Branch If Equal, Branch Not Equal, Branch Less Than, Branch Greater Than, Branch Less Than Unsigned, Branch Greater Than Unsigned
      OPCODE_BRANCH: begin
        imm_sel = IMM_BRANCH;
        id_wr_en = '0;
        use_b = '1;
        id_alu_op = ALU_ADD;
        id_a_gets_npc = '1;
        case (funct3)
          3'b000 /* BEQ  */: begin
            id_br_type = BR_EQ;
            id_br_uns = '0;
          end
          3'b001 /* BNE  */: begin
            id_br_type = BR_NE;
            id_br_uns = '0;
          end
          3'b100 /* BLT  */: begin
            id_br_type = BR_LT;
            id_br_uns = '0;
          end
          3'b101 /* BGE  */: begin
            id_br_type = BR_GE;
            id_br_uns = '0;
          end
          3'b110 /* BLTU */: begin
            id_br_type = BR_LT;
            id_br_uns = '1;
          end
          3'b111 /* BGEU */: begin
            id_br_type = BR_GE;
            id_br_uns = '1;
          end
        endcase
      end
      // load from memory into rd: Load Byte, Load Halfword, Load Word, Load Byte Unsigned, Load Halfword Unsigned
      OPCODE_LOAD: begin
        imm_sel = IMM_I_TYPE;
        id_alu_op = ALU_ADD;
        id_load = '1;
        case (funct3)
          3'b000 /* LB  */: begin
            id_byte_ls = '1;
          end
          3'b001 /* LH  */: begin
            id_half_ls = '1;
          end
          3'b010 /* LW  */: begin
          end
          3'b100 /* LBU */: begin
            id_byte_ls = '1;
            id_uns_ls = '1;
          end
          3'b101 /* LHU */: begin
            id_half_ls = '1;
            id_uns_ls = '1;
          end
        endcase
      end
      // store to memory instructions: Store Byte, Store Halfword, Store Word
      OPCODE_STORE: begin
        imm_sel = IMM_STORE;
        id_wr_en = '0;
        use_b = '1;
        id_alu_op = ALU_ADD;
        id_store = '1;
        case (funct3)
          3'b000 /* SB */: begin
            id_byte_ls = '1;
          end
          3'b001 /* SH */: begin
            id_half_ls = '1;
          end
          3'b010 /* SW */: begin
          end
        endcase
			end
      // immediate ALU instructions: Add Immediate, Set Less Than Immediate, Set Less Than Immediate Unsigned, XOR Immediate,
      // OR Immediate, And Immediate, Shift Left Logical Immediate, Shift Right Logical Immediate, Shift Right Arithmetic Immediate
      OPCODE_OP_IMM: begin
        imm_sel = IMM_I_TYPE;
        case ({funct7, funct3})
          10'bxxxxxxx000 /* ADDI  */: begin
            id_alu_op = ALU_ADD;
          end
          10'bxxxxxxx010 /* SLTI  */: begin
            id_alu_op = ALU_SLT;
          end
          10'bxxxxxxx011 /* SLTIU */: begin
            id_alu_op = ALU_SLTU;
          end
          10'bxxxxxxx100 /* XORI  */: begin
            id_alu_op = ALU_XOR;
          end
          10'bxxxxxxx110 /* ORI   */: begin
            id_alu_op = ALU_OR;
          end
          10'bxxxxxxx111 /* ANDI  */: begin
            id_alu_op = ALU_AND;
          end
          10'b0000000001 /* SLLI  */: begin
            id_alu_op = ALU_SLL;
          end
          10'b0000000101 /* SRLI  */: begin
            id_alu_op = ALU_SRL;
          end
          10'b0100000101 /* SRAI  */: begin
            id_alu_op = ALU_SRA;
          end
        endcase
      end
      // ALU instructions: Add, Subtract, Shift Left Logical, Set Left Than, Set Less Than Unsigned, XOR, Shift Right Logical,
      // Shift Right Arithmetic, OR, AND
      OPCODE_OP: begin
        use_b = '1;
        id_imm = '0;
        case ({funct7, funct3})
          10'b0000000000 /* ADD  */: begin
            id_alu_op = ALU_ADD;
          end
          10'b0100000000 /* SUB  */: begin
            id_alu_op = ALU_SUB;
          end
          10'b0000000001 /* SLL  */: begin
            id_alu_op = ALU_SLL;
          end
          10'b0000000010 /* SLT  */: begin
            id_alu_op = ALU_SLT;
          end
          10'b0000000011 /* SLTU */: begin
            id_alu_op = ALU_SLTU;
          end
          10'b0000000100 /* XOR  */: begin
            id_alu_op = ALU_XOR;
          end
          10'b0000000101 /* SRL  */: begin
            id_alu_op = ALU_SRL;
          end
          10'b0100000101 /* SRA  */: begin
            id_alu_op = ALU_SRA;
          end
          10'b0000000110 /* OR   */: begin
            id_alu_op = ALU_OR;
          end
          10'b0000000111 /* AND  */: begin
            id_alu_op = ALU_AND;
          end
        endcase
      end
      default: begin
        imm_sel = IMM_XXX;

        id_wr_en = 'x;
        use_a = 'x;
        use_b = 'x;
        a_gets0 = 'x;

        id_alu_op = ALU_XXX;
        id_imm = 'x;
        id_br_type = BR_XXX;
        id_br_uns = 'x;
        id_jump = 'x;
        id_a_gets_npc = 'x;
        id_load = 'x;

        id_store = 'x;
        id_byte_ls = 'x;
        id_half_ls = 'x;
        id_uns_ls  = 'x;
      end
    endcase
  end

  // Bypasses

  assign a_ex_byp = ({rs1, '1} == {ex_wr_reg, ex_wr_en});
  assign a_mem_byp = ({rs1, '1} == {mem_wr_reg, mem_wr_en});
  assign a_wb_byp = ({rs1, '1} == {wb_wr_reg, wb_wr_en});

  always_comb begin
    unique case (1'b1)
      a_gets0:   ex_a_sel = 2'b11; // LUI (a = 0)
      a_wb_byp:  ex_a_sel = 2'b10; // WB bypass
      a_mem_byp: ex_a_sel = 2'b01; // MEM bypass
      default:   ex_a_sel = 2'b00; // rs1
    endcase
  end

  assign b_ex_byp = ({rs2, '1} == {ex_wr_reg, ex_wr_en});
  assign b_mem_byp = ({rs2, '1} == {mem_wr_reg, mem_wr_en});
  assign b_wb_byp = ({rs2, '1} == {wb_wr_reg, wb_wr_en});

  always_comb begin
    unique case (1'b1)
      id_imm:    ex_b_sel = 2'b11;
      b_wb_byp:  ex_b_sel = 2'b10;
      b_mem_byp: ex_b_sel = 2'b01;
      default:   ex_b_sel = 2'b00;
    endcase
  end

  // Hazard detection logic
  // Load-use hazard: Current instruction in ID stage needs data from a load in
  // EX stage. The load data won't be available until after MEM stage, so we
  // must stall.
  assign load_use_stall = 
      (use_a && a_ex_byp && ex_load) || 
      (use_a && a_mem_byp && mem_load) || 
      (use_b && b_ex_byp && ex_load) || 
      (use_b && b_mem_byp && mem_load);
  // Load-store hazard: Store instruction in ID stage needs data from a load in
  // MEM stage. The load data won't be ready in time for the store.
  assign load_store_stall = id_store && mem_load;
  // DMA hazard signals
  assign id_dma_cycle = (dma_dm_to_id || dma_id_to_dm) && !dma_imem_select;
  assign dmem_dma_stall = (id_dma_cycle || mem_dma_cycle) && (id_store || id_load);

  // id_adv causes ID stage latches to be held if deasserted
  // ex_kill causes EX stages signals to be deasserted
  // To stall the pipe, id_adv = 0 and ex_kill = 1
  // To restart execution after a halt, for one cycle id_adv = 1 and ex_kill = 0

  assign id_adv = load_use_stall || load_store_stall || dmem_dma_stall;
  // When halt is deasserted the first non-halt cycle is valid in IF but not 
  // ID. The use of prev_halt in kill_re prevents issue of an ID instruction
  // before a valid instruction has reached ID.
  assign ex_kill = imem_dma_id || halt || prev_halt || id_adv;

  assign id_store_k = id_store && !ex_kill;
  assign id_load_k = id_load && !ex_kill;
  assign id_wr_en_k = id_wr_en && !ex_kill;
  assign id_br_type_k = branch_e'(id_br_type && !ex_kill);
  assign id_jump_k = id_jump && !ex_kill;
  assign id_a_gets_npc_k = id_a_gets_npc && !ex_kill;
  assign id_byte_ls_k = id_byte_ls && !ex_kill;
  assign id_half_ls_k = id_half_ls && !ex_kill;
  assign id_uns_ls_k = id_uns_ls && !ex_kill;

  // ID / EX
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
    end
    else begin
      alu_op        <= id_alu_op;
      br_uns        <= id_br_uns;

      ex_dma_cycle  <= id_dma_cycle;

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
    end
  end

  // Select next_pc for B/JAL/AUIPC
  assign alu_a_sel = ex_a_gets_npc;

  // Branch checks
  assign taken = ex_jump ||           // JAL/R
      ((ex_br_type[0]) && br_eq) ||   // BEQ
      ((ex_br_type[1]) && !br_eq) ||  // BNE
      ((ex_br_type[2]) && br_lt) ||   // BLT/U
      ((ex_br_type[3]) && !br_lt);    // BGE/U

  // If there's a branch taken in in EX but no id_adv (or we are halting), we
  // need to save the information that there has been a branch and the target
  // must be fetched.
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) prev_halt <= '0;
    else        prev_halt <= halt;

  assign imem_dma_ppif = (dma_dm_to_id || dma_id_to_dm) && dma_imem_select;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) imem_dma_pif <= '0;
    else        imem_dma_pif <= imem_dma_ppif;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) imem_dma_if <= '0;
    else        imem_dma_if <= imem_dma_pif;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) imem_dma_id <= '0;
    else        imem_dma_id <= imem_dma_if;

  // EX / MEM
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_dma_cycle <= '0;

      mem_load      <= '0;
      mem_wr_reg    <= '0;
      mem_wr_en     <= '0;
      mem_jump      <= '0;
    end
    else begin
      mem_dma_cycle <= ex_dma_cycle;

      mem_load      <= ex_load;
      mem_wr_reg    <= ex_wr_reg;
      mem_wr_en     <= ex_wr_en;
      mem_jump      <= ex_jump;
    end
  end

  // MEM / WB
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wb_load   <= '0;
      wb_wr_reg <= '0;
      wb_wr_en  <= '0;
      wb_jump   <= '0;
    end
    else begin
      wb_load   <= mem_load;
      wb_wr_reg <= mem_wr_reg;
      wb_wr_en  <= mem_wr_en;
      wb_jump   <= mem_jump;
    end
  end

  assign rf_w = wb_wr_reg;
  assign rf_wen = wb_wr_en;

  // Writeback value select
  always_comb begin
    if      (wb_load) wb_sel = 2'b00; // loads
    else if (wb_jump) wb_sel = 2'b10; // JAL/R
    else              wb_sel = 2'b01; // other (writeback ALU)
  end

endmodule: control
