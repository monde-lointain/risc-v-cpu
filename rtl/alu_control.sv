/***********************************************************************
   alu control 
 ***********************************************************************/

module alu_control
 import definitions_pkg::*;
(input  logic [1:0] alu_op, 
 input  logic [6:0] funct7,
 input  logic [2:0] funct3, 
 output alu_sel_e    opcode
);

  always_comb begin
    case ({alu_op, funct7, funct3}) inside
      // LW or SW operand
      12'b00xxxxxxxxxx: opcode = ADD; 
      // BEQ operand
      12'bx1xxxxxxxxxx: opcode = SUB; 
      // ADD operand
      12'b1x0000000000: opcode = ADD; 
      // SUB operand
      12'b1x0100000000: opcode = SUB; 
      // AND operand
      12'b1x0000000111: opcode = AND; 
      // OR operand
      12'b1x0000000110: opcode = OR; 
      default:          opcode = XXX; 
    endcase
  end

endmodule: alu_control
