/***********************************************************************
   instruction decode unit: this block is based on the instruction
   decode segment from the NERV RISC-V educational processor: 

     https://github.com/YosysHQ/nerv
 ***********************************************************************/

module inst_decode
import definitions_pkg::*;
(input  logic [31:0] inst,
 output logic [ 4:0] rf_ra, rf_rb, rf_rd,
 output imm_e        imm_sel,
 output alu_e        id_alu
);

  logic [6:0] funct7 = inst[31:25];
  logic [4:0] rs2 = inst[24:20];
  logic [4:0] rs1 = inst[19:15];
  logic [2:0] funct3 = inst[14:12];
  logic [4:0] rd = inst[11:7];
  logic [6:0] opcode = inst[6:0];
  
  assign rf_ra = rs1;
  assign rf_rb = rs2;
  assign rf_rd = rd;
  
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

  logic id_wr_reg;

  // act on opcodes
  always_comb begin
    id_alu = ALU_XXX;
    imm_sel = IMM_XXX;
    id_wr_reg = 0;
    case (opcode)
      // Load Upper Immediate
      OPCODE_LUI: begin
        id_alu = ALU_LUI;
        imm_sel = IMM_U_TYPE;
      end
      // Add Upper Immediate to Program Counter
      OPCODE_AUIPC: begin
        id_alu = ALU_ADD;
        imm_sel = IMM_U_TYPE;
      end
      // Jump And Link (unconditional jump)
      OPCODE_JAL: begin
        id_alu = ALU_ADD;
        imm_sel = IMM_JAL;
      end
      // Jump And Link Register (indirect jump)
      OPCODE_JALR: begin
        id_alu = ALU_ADD;
        imm_sel = IMM_I_TYPE;
      end
      // branch instructions: Branch If Equal, Branch Not Equal, Branch Less Than, Branch Greater Than, Branch Less Than Unsigned, Branch Greater Than Unsigned
      OPCODE_BRANCH: begin
        id_alu = ALU_ADD;
        imm_sel = IMM_BRANCH;
      end
      // load from memory into rd: Load Byte, Load Halfword, Load Word, Load Byte Unsigned, Load Halfword Unsigned
      OPCODE_LOAD: begin
        id_alu = ALU_ADD;
        imm_sel = IMM_I_TYPE;
        id_wr_reg = 1;
      end
      // store to memory instructions: Store Byte, Store Halfword, Store Word
      OPCODE_STORE: begin
        id_alu = ALU_ADD;
        imm_sel = IMM_STORE;
			end
      // immediate ALU instructions: Add Immediate, Set Less Than Immediate, Set Less Than Immediate Unsigned, XOR Immediate,
      // OR Immediate, And Immediate, Shift Left Logical Immediate, Shift Right Logical Immediate, Shift Right Arithmetic Immediate
      OPCODE_OP_IMM: begin
        case ({funct7, funct3})
          10'bzzzzzzz000 /* ADDI  */: id_alu = ALU_ADD;
          10'bzzzzzzz010 /* SLTI  */: id_alu = ALU_SLT;
          10'bzzzzzzz011 /* SLTIU */: id_alu = ALU_SLTU;
          10'bzzzzzzz100 /* XORI  */: id_alu = ALU_XOR;
          10'bzzzzzzz110 /* ORI   */: id_alu = ALU_OR;
          10'bzzzzzzz111 /* ANDI  */: id_alu = ALU_AND;
          10'b0000000001 /* SLLI  */: id_alu = ALU_SLL;
          10'b0000000101 /* SRLI  */: id_alu = ALU_SRL;
          10'b0100000101 /* SRAI  */: id_alu = ALU_SRA;
        endcase
        imm_sel = IMM_I_TYPE;
      end
      // ALU instructions: Add, Subtract, Shift Left Logical, Set Left Than, Set Less Than Unsigned, XOR, Shift Right Logical,
      // Shift Right Arithmetic, OR, AND
      OPCODE_OP: begin
        case ({funct7, funct3})
          10'b0000000000 /* ADD  */: id_alu = ALU_ADD;
          10'b0100000000 /* SUB  */: id_alu = ALU_SUB;
          10'b0000000001 /* SLL  */: id_alu = ALU_SLL;
          10'b0000000010 /* SLT  */: id_alu = ALU_SLT;
          10'b0000000011 /* SLTU */: id_alu = ALU_SLTU;
          10'b0000000100 /* XOR  */: id_alu = ALU_XOR;
          10'b0000000101 /* SRL  */: id_alu = ALU_SRL;
          10'b0100000101 /* SRA  */: id_alu = ALU_SRA;
          10'b0000000110 /* OR   */: id_alu = ALU_OR;
          10'b0000000111 /* AND  */: id_alu = ALU_AND;
        endcase
      end
    endcase
  end

endmodule: inst_decode
