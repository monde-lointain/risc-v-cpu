/***********************************************************************
   simple alu
 ***********************************************************************/

module alu
 import definitions_pkg::*;
(input  instruction_t iw, 
 output logic [31:0]  result,
 output logic         zero
);

  always_comb begin
    case (iw.opcode)
      AND: result = iw.a & iw.b;
      OR : result = iw.a | iw.b;
      ADD: result = iw.a + iw.b;
      SUB: result = iw.a - iw.b;
      default: result = 0;
    endcase

    zero = (result == 0);
  end

endmodule: alu
