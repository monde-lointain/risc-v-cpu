/***********************************************************************
   instruction decode unit: this block is based on the instruction
   decode segment from the NERV RISC-V educational processor: 

     https://github.com/YosysHQ/nerv
 ***********************************************************************/

module inst_decode
import definitions_pkg::*;
(input  logic        beq, blt,
 input  logic [31:0] inst,
 output logic        taken, br_un, a_sel, b_sel, mem_rw, rf_wen,
 output logic [1:0]  wb_sel,
 output imm_e        imm_sel,
 output alu_e        alu_sel
);

  logic [6:0] funct7 = inst[31:25];
  logic [2:0] funct3 = inst[14:12];
  logic [6:0] opcode = inst[6:0];
  
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

  // act on opcodes
  always_comb begin
    alu_sel = ALU_XXX;
    imm_sel = IMM_XXX;
    {taken, br_un, a_sel, b_sel, mem_rw, rf_wen, wb_sel} = 'x;
    case (opcode)
      // Load Upper Immediate
      OPCODE_LUI: begin
        taken   = 0;
        imm_sel = IMM_U_TYPE;
        b_sel   = 1;
        alu_sel = ALU_ADD;
        mem_rw  = 0;
        rf_wen  = 1;
        wb_sel  = 2'b01;
      end
      // Add Upper Immediate to Program Counter
      OPCODE_AUIPC: begin
        taken   = 0;
        imm_sel = IMM_U_TYPE;
        a_sel   = 1;
        b_sel   = 1;
        alu_sel = ALU_ADD;
        mem_rw  = 0;
        rf_wen  = 1;
        wb_sel  = 2'b01;
      end
      // Jump And Link (unconditional jump)
      OPCODE_JAL: begin
        taken   = 1;
        imm_sel = IMM_JAL;
        a_sel   = 1;
        b_sel   = 1;
        alu_sel = ALU_ADD;
        mem_rw  = 0;
        rf_wen  = 1;
        wb_sel  = 2'b10;
      end
      // Jump And Link Register (indirect jump)
      OPCODE_JALR: begin
        taken   = 1;
        imm_sel = IMM_I_TYPE;
        a_sel   = 0;
        b_sel   = 1;
        alu_sel = ALU_ADD;
        mem_rw  = 0;
        rf_wen  = 1;
        wb_sel  = 2'b10;
      end
      // branch instructions: Branch If Equal, Branch Not Equal, Branch Less Than, Branch Greater Than, Branch Less Than Unsigned, Branch Greater Than Unsigned
      OPCODE_BRANCH: begin
        imm_sel = IMM_BRANCH;
        a_sel   = 1;
        b_sel   = 1;
        alu_sel = ALU_ADD;
        mem_rw  = 0;
        rf_wen  = 0;
        case (funct3)
          3'b000 /* BEQ  */: taken = beq ? 1 : 0;
          3'b001 /* BNE  */: taken = beq ? 0 : 1;
          3'b100 /* BLT  */: begin
            br_un = 0;
            taken = blt ? 1 : 0;
          end
          3'b101 /* BGE  */: begin
            br_un = 0;
            taken = blt ? 0 : 1;
          end
          3'b110 /* BLTU */: begin
            br_un = 1;
            taken = blt ? 1 : 0;
          end
          3'b111 /* BGEU */: begin
            br_un = 1;
            taken = blt ? 0 : 1;
          end
        endcase
      end
      // load from memory into rd: Load Byte, Load Halfword, Load Word, Load Byte Unsigned, Load Halfword Unsigned
      OPCODE_LOAD: begin
        taken   = 0;
        imm_sel = IMM_I_TYPE;
        a_sel   = 0;
        b_sel   = 1;
        alu_sel = ALU_ADD;
        mem_rw  = 0;
        rf_wen  = 1;
        wb_sel  = 2'b00;
      end
      // store to memory instructions: Store Byte, Store Halfword, Store Word
      OPCODE_STORE: begin
        taken   = 0;
        imm_sel = IMM_STORE;
        a_sel   = 0;
        b_sel   = 1;
        alu_sel = ALU_ADD;
        mem_rw  = 1;
        rf_wen  = 0;
			end
      // immediate ALU instructions: Add Immediate, Set Less Than Immediate, Set Less Than Immediate Unsigned, XOR Immediate,
      // OR Immediate, And Immediate, Shift Left Logical Immediate, Shift Right Logical Immediate, Shift Right Arithmetic Immediate
      OPCODE_OP_IMM: begin
        taken   = 0;
        imm_sel = IMM_I_TYPE;
        a_sel   = 0;
        b_sel   = 0;
        mem_rw  = 0;
        rf_wen  = 1;
        wb_sel  = 2'b01;
        case ({funct7, funct3})
          10'bzzzzzzz000 /* ADDI  */: alu_sel = ALU_ADD;
          10'bzzzzzzz010 /* SLTI  */: alu_sel = ALU_SLT;
          10'bzzzzzzz011 /* SLTIU */: alu_sel = ALU_SLTU;
          10'bzzzzzzz100 /* XORI  */: alu_sel = ALU_XOR;
          10'bzzzzzzz110 /* ORI   */: alu_sel = ALU_OR;
          10'bzzzzzzz111 /* ANDI  */: alu_sel = ALU_AND;
          10'b0000000001 /* SLLI  */: alu_sel = ALU_SLL;
          10'b0000000101 /* SRLI  */: alu_sel = ALU_SRL;
          10'b0100000101 /* SRAI  */: alu_sel = ALU_SRA;
        endcase
      end
      // ALU instructions: Add, Subtract, Shift Left Logical, Set Left Than, Set Less Than Unsigned, XOR, Shift Right Logical,
      // Shift Right Arithmetic, OR, AND
      OPCODE_OP: begin
        taken   = 0;
        a_sel   = 0;
        b_sel   = 0;
        mem_rw  = 0;
        rf_wen  = 1;
        wb_sel  = 2'b01;
        case ({funct7, funct3})
          10'bzzzzzzz000 /* ADDI  */: alu_sel = ALU_ADD;
          10'bzzzzzzz010 /* SLTI  */: alu_sel = ALU_SLT;
          10'bzzzzzzz011 /* SLTIU */: alu_sel = ALU_SLTU;
          10'bzzzzzzz100 /* XORI  */: alu_sel = ALU_XOR;
          10'bzzzzzzz110 /* ORI   */: alu_sel = ALU_OR;
          10'bzzzzzzz111 /* ANDI  */: alu_sel = ALU_AND;
          10'b0000000001 /* SLLI  */: alu_sel = ALU_SLL;
          10'b0000000101 /* SRLI  */: alu_sel = ALU_SRL;
          10'b0100000101 /* SRAI  */: alu_sel = ALU_SRA;
        endcase
        case ({funct7, funct3})
          10'b0000000000 /* ADD  */: alu_sel = ALU_ADD;
          10'b0100000000 /* SUB  */: alu_sel = ALU_SUB;
          10'b0000000001 /* SLL  */: alu_sel = ALU_SLL;
          10'b0000000010 /* SLT  */: alu_sel = ALU_SLT;
          10'b0000000011 /* SLTU */: alu_sel = ALU_SLTU;
          10'b0000000100 /* XOR  */: alu_sel = ALU_XOR;
          10'b0000000101 /* SRL  */: alu_sel = ALU_SRL;
          10'b0100000101 /* SRA  */: alu_sel = ALU_SRA;
          10'b0000000110 /* OR   */: alu_sel = ALU_OR;
          10'b0000000111 /* AND  */: alu_sel = ALU_AND;
        endcase
      end
    endcase
  end

endmodule: inst_decode
