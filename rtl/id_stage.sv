/***********************************************************************
   cpu datapath 
 ***********************************************************************/

module id_stage
import definitions_pkg::*;
(input  logic        clk, rf_wen,
 input  logic [31:0] inst,
 input  logic [31:0] wb_data,
 output logic [31:0] imm_data, rs1, rs2,
 output alu_e        alu_sel
);

  logic [31:0] i_imm, s_imm, b_imm, jal_imm, u_imm;
  logic [ 4:0] rf_ra, rf_rb, rf_w;
  imm_e imm_sel;

  inst_decode instruction_decoder(.inst, .rf_ra, .rf_rb, .rf_rd(rf_w), .imm_sel, .id_alu(alu_sel));

  assign i_imm   = {{20{inst[31]}}, inst[31:20]};
  assign s_imm   = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  assign b_imm   = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  assign jal_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
  assign u_imm   = {{inst[31:12]}, 12'b0};

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

  register_file regfile(.clk(clk), .wen(rf_wen), .d(wb_data), .ra(rf_ra), .rb(rf_rb), .w(rf_w), .a(rs1), .b(rs2));

endmodule: id_stage
