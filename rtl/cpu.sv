/***********************************************************************
   cpu top-level module
 ***********************************************************************/

module cpu
import definitions_pkg::*;
(input  logic clk, rst_n, taken, halting, imem_nwr, imem_ncs, rf_wen,
 input  logic [9:0] br_addr,
 input  logic [31:0] imem_din,
 input  logic [31:0] wb_data,
 output logic [31:0] imm_data, rs1, rs2,
 output alu_e        alu_sel
);

  logic [31:0] inst;

  if_stage if_stage(.*);
  id_stage id_stage(.*);

endmodule: cpu
