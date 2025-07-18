/***********************************************************************
   simple alu
 ***********************************************************************/

module alu
 import definitions_pkg::*;
(input  alu_op_t      op, 
 output logic [31:0]  result,
 output logic         zero
);

  always_comb begin
    case (op.opcode)
      AND:     result = op.a & op.b;
      OR :     result = op.a | op.b;
      ADD:     result = op.a + op.b;
      SUB:     result = op.a - op.b;
      default: result = 0;
    endcase
  end

  assign zero = (result == 0);

endmodule: alu
