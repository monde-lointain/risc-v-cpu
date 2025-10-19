module control
import definitions_pkg::*;
(input  logic        clk, rst_n,
 input  logic [31:0] inst,
 input  logic        br_eq, br_lt,
 output logic        taken,
 output logic [ 4:0] rf_ra, rf_rb, rf_w,
 output logic        rf_wen,
 output logic        wben,
 output logic [ 2:0] rd_a_sel, rd_b_sel,
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

  logic [6:0] opcode;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic [4:0] rd_wr_reg;
  logic [4:0] ex_wr_reg;
  logic [4:0] df_wr_reg;
  logic [4:0] wb_wr_reg;
  logic       rd_wr_en;
  logic       ex_wr_en;
  logic       df_wr_en;
  logic       wb_wr_en;
  logic       a_gets0;
  logic       a_ex_byp;
  logic       a_df_byp;
  logic       a_wb_byp;

  alu_e       rd_alu_op;
  logic       rd_imm;
  branch_e    rd_br_type;
  branch_e    ex_br_type;
  logic       rd_br_uns;
  logic       rd_jump;
  logic       ex_jump;
  logic       rd_a_gets_npc;
  logic       ex_a_gets_npc;
  logic       rd_load;
  logic       df_load;
  logic       wb_load;

  logic       rd_store;
  logic       rd_byte_ls;
  logic       rd_half_ls;
  logic       rd_uns_ls;

  assign opcode = inst[6:0];
  assign funct7 = inst[31:25];
  assign funct3 = inst[14:12];
  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];

  assign rf_ra = rs1;
  assign rf_rb = rs2;
  assign rd_wr_reg = rd;

  // act on opcodes
  always_comb begin
    imm_sel = IMM_XXX;

    rd_wr_en = '1;
    a_gets0  = '0;

    rd_alu_op = ALU_XXX;
    rd_imm = '1;
    rd_br_type = BR_XXX;
    rd_br_uns = 'x;
    rd_jump = '0;
    rd_a_gets_npc = '0;
    rd_load = '0;

    rd_store = '0;
    rd_byte_ls = '0;
    rd_half_ls = '0;
    rd_uns_ls = '0;

    case (opcode)
      // Load Upper Immediate
      OPCODE_LUI: begin
        imm_sel = IMM_U_TYPE;
        a_gets0 = '1;
        rd_alu_op = ALU_LUI;
      end
      // Add Upper Immediate to Program Counter
      OPCODE_AUIPC: begin
        imm_sel = IMM_U_TYPE;
        rd_alu_op = ALU_ADD;
        rd_a_gets_npc = '1;
      end
      // Jump And Link (unconditional jump)
      OPCODE_JAL: begin
        imm_sel = IMM_JAL;
        rd_alu_op = ALU_ADD;
        rd_jump = '1;
        rd_a_gets_npc = '1;
      end
      // Jump And Link Register (indirect jump)
      OPCODE_JALR: begin
        imm_sel = IMM_I_TYPE;
        rd_alu_op = ALU_ADD;
        rd_jump = '1;
      end
      // branch instructions: Branch If Equal, Branch Not Equal, Branch Less Than, Branch Greater Than, Branch Less Than Unsigned, Branch Greater Than Unsigned
      OPCODE_BRANCH: begin
        imm_sel = IMM_BRANCH;
        rd_wr_en = '0;
        rd_alu_op = ALU_ADD;
        rd_a_gets_npc = '1;
        case (funct3)
          3'b000 /* BEQ  */: begin
            rd_br_type = BR_EQ;
            rd_br_uns = '0;
          end
          3'b001 /* BNE  */: begin
            rd_br_type = BR_NE;
            rd_br_uns = '0;
          end
          3'b100 /* BLT  */: begin
            rd_br_type = BR_LT;
            rd_br_uns = '0;
          end
          3'b101 /* BGE  */: begin
            rd_br_type = BR_GE;
            rd_br_uns = '0;
          end
          3'b110 /* BLTU */: begin
            rd_br_type = BR_LT;
            rd_br_uns = '1;
          end
          3'b111 /* BGEU */: begin
            rd_br_type = BR_GE;
            rd_br_uns = '1;
          end
        endcase
      end
      // load from memory into rd: Load Byte, Load Halfword, Load Word, Load Byte Unsigned, Load Halfword Unsigned
      OPCODE_LOAD: begin
        imm_sel = IMM_I_TYPE;
        rd_alu_op = ALU_ADD;
        rd_load = '1;
        case (funct3)
          3'b000 /* LB  */: begin
            rd_byte_ls = '1;
          end
          3'b001 /* LH  */: begin
            rd_half_ls = '1;
          end
          3'b010 /* LW  */: begin
          end
          3'b100 /* LBU */: begin
            rd_byte_ls = '1;
            rd_uns_ls = '1;
          end
          3'b101 /* LHU */: begin
            rd_half_ls = '1;
            rd_uns_ls = '1;
          end
        endcase
      end
      // store to memory instructions: Store Byte, Store Halfword, Store Word
      OPCODE_STORE: begin
        imm_sel = IMM_STORE;
        rd_wr_en = '0;
        rd_alu_op = ALU_ADD;
        rd_store = '1;
        case (funct3)
          3'b000 /* SB */: begin
            rd_byte_ls = '1;
          end
          3'b001 /* SH */: begin
            rd_half_ls = '1;
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
            rd_alu_op = ALU_ADD;
          end
          10'bxxxxxxx010 /* SLTI  */: begin
            rd_alu_op = ALU_SLT;
          end
          10'bxxxxxxx011 /* SLTIU */: begin
            rd_alu_op = ALU_SLTU;
          end
          10'bxxxxxxx100 /* XORI  */: begin
            rd_alu_op = ALU_XOR;
          end
          10'bxxxxxxx110 /* ORI   */: begin
            rd_alu_op = ALU_OR;
          end
          10'bxxxxxxx111 /* ANDI  */: begin
            rd_alu_op = ALU_AND;
          end
          10'b0000000001 /* SLLI  */: begin
            rd_alu_op = ALU_SLL;
          end
          10'b0000000101 /* SRLI  */: begin
            rd_alu_op = ALU_SRL;
          end
          10'b0100000101 /* SRAI  */: begin
            rd_alu_op = ALU_SRA;
          end
        endcase
      end
      // ALU instructions: Add, Subtract, Shift Left Logical, Set Left Than, Set Less Than Unsigned, XOR, Shift Right Logical,
      // Shift Right Arithmetic, OR, AND
      OPCODE_OP: begin
        rd_imm = '0;
        case ({funct7, funct3})
          10'b0000000000 /* ADD  */: begin
            rd_alu_op = ALU_ADD;
          end
          10'b0100000000 /* SUB  */: begin
            rd_alu_op = ALU_SUB;
          end
          10'b0000000001 /* SLL  */: begin
            rd_alu_op = ALU_SLL;
          end
          10'b0000000010 /* SLT  */: begin
            rd_alu_op = ALU_SLT;
          end
          10'b0000000011 /* SLTU */: begin
            rd_alu_op = ALU_SLTU;
          end
          10'b0000000100 /* XOR  */: begin
            rd_alu_op = ALU_XOR;
          end
          10'b0000000101 /* SRL  */: begin
            rd_alu_op = ALU_SRL;
          end
          10'b0100000101 /* SRA  */: begin
            rd_alu_op = ALU_SRA;
          end
          10'b0000000110 /* OR   */: begin
            rd_alu_op = ALU_OR;
          end
          10'b0000000111 /* AND  */: begin
            rd_alu_op = ALU_AND;
          end
        endcase
      end
      default: begin
        imm_sel = IMM_XXX;

        rd_wr_en = 'x;
        a_gets0 = 'x;

        rd_alu_op = ALU_XXX;
        rd_imm = 'x;
        rd_br_type = BR_XXX;
        rd_br_uns = 'x;
        rd_jump = 'x;
        rd_a_gets_npc = 'x;
        rd_load = 'x;

        rd_store = 'x;
        rd_byte_ls = 'x;
        rd_half_ls = 'x;
        rd_uns_ls  = 'x;
      end
    endcase
  end

  // Bypasses

  assign a_ex_byp = ({rs1, '1} == {ex_wr_reg, ex_wr_en});
  assign a_df_byp = ({rs1, '1} == {df_wr_reg, df_wr_en});
  assign a_wb_byp = ({rs1, '1} == {wb_wr_reg, wb_wr_en});

  always_comb begin
    unique case (1'b1)
      a_gets0:  rd_a_sel = 3'b100; // LUI (a = 0)
      a_wb_byp: rd_a_sel = 3'b011; // WB bypass
      a_df_byp: rd_a_sel = 3'b010; // DF bypass
      a_ex_byp: rd_a_sel = 3'b001; // EX bypass
      default:  rd_a_sel = 3'b000; // rs1
    endcase
  end

  assign b_ex_byp = ({rs2, '1} == {ex_wr_reg, ex_wr_en});
  assign b_df_byp = ({rs2, '1} == {df_wr_reg, df_wr_en});
  assign b_wb_byp = ({rs2, '1} == {wb_wr_reg, wb_wr_en});

  always_comb begin
    unique case (1'b1)
      rd_imm:   rd_b_sel = 3'b100;
      b_wb_byp: rd_b_sel = 3'b011;
      b_df_byp: rd_b_sel = 3'b010;
      b_ex_byp: rd_b_sel = 3'b001;
      default:  rd_b_sel = 3'b000;
    endcase
  end

  // RD / EX
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
      alu_op        <= rd_alu_op;
      br_uns        <= rd_br_uns;

      ex_store      <= rd_store;
      ex_load       <= rd_load;

      ex_wr_reg     <= rd_wr_reg;
      ex_wr_en      <= rd_wr_en;

      ex_br_type    <= rd_br_type;
      ex_jump       <= rd_jump;
      ex_a_gets_npc <= rd_a_gets_npc;

      ex_byte_ls    <= rd_byte_ls;
      ex_half_ls    <= rd_half_ls;
      ex_uns_ls     <= rd_uns_ls;
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

  // EX / DF
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      df_load    <= '0;
      df_wr_reg  <= '0;
      df_wr_en   <= '0;
    end
    else begin
      df_load    <= ex_load;
      df_wr_reg  <= ex_wr_reg;
      df_wr_en   <= ex_wr_en;
    end
  end

  // DF / WB
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wb_load    <= '0;
      wb_wr_reg  <= '0;
      wb_wr_en   <= '0;
    end
    else begin
      wb_load    <= df_load;
      wb_wr_reg  <= df_wr_reg;
      wb_wr_en   <= df_wr_en;
    end
  end

  assign rf_w = wb_wr_reg;
  assign rf_wen = wb_wr_en;
  assign wben = !wb_load;

endmodule: control
