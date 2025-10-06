/***********************************************************************
   alu
 ***********************************************************************/

module alu
import definitions_pkg::*;
(input  logic [31:0] a, b,
 input  alu_e        sel,
 output logic [31:0] result
);

  always_comb begin
    case (sel)
      ALU_ADD:  result = a + b;
      ALU_SUB:  result = a - b; 
      ALU_SLL:  result = a << b; 
      ALU_SLT:  result = signed'(a) < signed'(b);
      ALU_SLTU: result = a < b;
      ALU_XOR:  result = a ^ b;
      ALU_SRL:  result = a >> b;
      ALU_SRA:  result = a >>> b;  
      ALU_OR:   result = a | b;  
      ALU_AND:  result = a & b;  
      default:  result = 0;
    endcase
  end

endmodule: alu
