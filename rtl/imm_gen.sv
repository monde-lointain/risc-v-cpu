/***********************************************************************
   immediate generation
 ***********************************************************************/

module imm_gen
import definitions_pkg::*;
(input  imm_e        imm_sel,
 input  logic [31:0] inst,
 output logic [31:0] imm_data
);

  logic [31:0] i_imm   = {{20{inst[31]}}, inst[31:20]};
  logic [31:0] s_imm   = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  logic [31:0] b_imm   = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  logic [31:0] jal_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
  logic [31:0] u_imm   = {{inst[31:12]}, 12'b0};

  always_comb begin
    imm_data = 'x;
    case (imm_sel)
      IMM_I_TYPE: imm_data = i_imm;
      IMM_STORE : imm_data = s_imm;
      IMM_BRANCH: imm_data = b_imm;
      IMM_JAL   : imm_data = jal_imm;
      IMM_U_TYPE: imm_data = u_imm;
      default   : imm_data = 'x;
    endcase
  end

endmodule: imm_gen
