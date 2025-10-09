/***********************************************************************
   immediate generation
 ***********************************************************************/

module imm_gen
import definitions_pkg::*;
(input  imm_e        imm_sel,
 input  logic [31:0] inst,
 output logic [31:0] imm_data
);

  always_comb begin
    imm_data = 'x;
    case (imm_sel)
      IMM_I_TYPE: imm_data = {{20{inst[31]}}, inst[31:20]};
      IMM_STORE : imm_data = {{20{inst[31]}}, inst[31:25], inst[11:7]};
      IMM_BRANCH: imm_data = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
      IMM_JAL   : imm_data = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
      IMM_U_TYPE: imm_data = {{inst[31:12]}, 12'b0};
      default   : imm_data = 'x;
    endcase
  end

endmodule: imm_gen
