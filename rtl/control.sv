module control
(input  logic        clk, rst_n,
 input  logic [31:0] su_inst,
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

  logic [6:0] funct7 = inst[31:25];
  logic [2:0] funct3 = inst[14:12];
  logic [6:0] opcode = inst[6:0];

  // act on opcodes
  always_comb begin
    case (opcode)
      // Load Upper Immediate
      OPCODE_LUI: begin
      end
      // Add Upper Immediate to Program Counter
      OPCODE_AUIPC: begin
      end
      // Jump And Link (unconditional jump)
      OPCODE_JAL: begin
      end
      // Jump And Link Register (indirect jump)
      OPCODE_JALR: begin
      end
      // branch instructions: Branch If Equal, Branch Not Equal, Branch Less Than, Branch Greater Than, Branch Less Than Unsigned, Branch Greater Than Unsigned
      OPCODE_BRANCH: begin
        case (funct3)
          3'b000 /* BEQ  */: begin
          end
          3'b001 /* BNE  */: begin
          end
          3'b100 /* BLT  */: begin
          end
          3'b101 /* BGE  */: begin
          end
          3'b110 /* BLTU */: begin
          end
          3'b111 /* BGEU */: begin
          end
        endcase
      end
      // load from memory into rd: Load Byte, Load Halfword, Load Word, Load Byte Unsigned, Load Halfword Unsigned
      OPCODE_LOAD: begin
        case (funct3)
          3'b000 /* LB  */: begin
          end
          3'b001 /* LH  */: begin
          end
          3'b010 /* LW  */: begin
          end
          3'b100 /* LBU */: begin
          end
          3'b101 /* LHU */: begin
          end
        endcase
      end
      // store to memory instructions: Store Byte, Store Halfword, Store Word
      OPCODE_STORE: begin
        case (funct3)
          3'b000 /* SB */: begin
          end
          3'b001 /* SH */: begin
          end
          3'b010 /* SW */: begin
          end
        endcase
			end
      // immediate ALU instructions: Add Immediate, Set Less Than Immediate, Set Less Than Immediate Unsigned, XOR Immediate,
      // OR Immediate, And Immediate, Shift Left Logical Immediate, Shift Right Logical Immediate, Shift Right Arithmetic Immediate
      OPCODE_OP_IMM: begin
        case ({funct7, funct3})
          10'bxxxxxxx000 /* ADDI  */: begin
          end
          10'bxxxxxxx010 /* SLTI  */: begin
          end
          10'bxxxxxxx011 /* SLTIU */: begin
          end
          10'bxxxxxxx100 /* XORI  */: begin
          end
          10'bxxxxxxx110 /* ORI   */: begin
          end
          10'bxxxxxxx111 /* ANDI  */: begin
          end
          10'b0000000001 /* SLLI  */: begin
          end
          10'b0000000101 /* SRLI  */: begin
          end
          10'b0100000101 /* SRAI  */: begin
          end
        endcase
      end
      // ALU instructions: Add, Subtract, Shift Left Logical, Set Left Than, Set Less Than Unsigned, XOR, Shift Right Logical,
      // Shift Right Arithmetic, OR, AND
      OPCODE_OP: begin
        case ({funct7, funct3})
          10'b0000000000 /* ADD  */: begin
          end
          10'b0000000001 /* SLL  */: begin
          end
          10'b0000000010 /* SLT  */: begin
          end
          10'b0000000011 /* SLTU */: begin
          end
          10'b0000000100 /* XOR  */: begin
          end
          10'b0000000101 /* SRL  */: begin
          end
          10'b0000000110 /* OR   */: begin
          end
          10'b0000000111 /* AND  */: begin
          end
          10'b0100000000 /* SUB  */: begin
          end
          10'b0100000101 /* SRA  */: begin
          end
        endcase
      end
    endcase
  end

endmodule: control
