/***********************************************************************
   alu control 
 ***********************************************************************/

module alu_control
 import control_defs::*;
(input  logic [1:0] alu_op, 
 input  logic [6:0] funct7,
 input  logic [2:0] funct3, 
 output alu_sel_e   alu_sel
);

  always_comb begin
    case ({alu_op, funct7, funct3}) inside
      // LW or SW operand
      12'b00xxxxxxxxxx: alu_sel = ADD; 
      // BEQ operand
      12'bx1xxxxxxxxxx: alu_sel = SUB; 
      // ADD operand
      12'b1x0000000000: alu_sel = ADD; 
      // SUB operand
      12'b1x0100000000: alu_sel = SUB; 
      // AND operand
      12'b1x0000000111: alu_sel = AND; 
      // OR operand
      12'b1x0000000110: alu_sel = OR; 
      default:          alu_sel = XXX; 
    endcase
  end

endmodule: alu_control
