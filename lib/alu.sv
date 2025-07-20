/***********************************************************************
   simple alu
 ***********************************************************************/

module alu
 import control_defs::*;
(input  alu_sel_e    sel, 
 input  logic [31:0] a, b,
 output logic [31:0] result,
 output logic        zero
);

  always_comb begin
    case (sel)
      AND:     result = a & b;
      OR :     result = a | b;
      ADD:     result = a + b;
      SUB:     result = a - b;
      default: result = 0;
    endcase
  end

  assign zero = (result == 0);

endmodule: alu
