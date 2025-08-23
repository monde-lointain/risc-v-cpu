/***********************************************************************
   top level cpu 
 ***********************************************************************/

module cpu
 import control_defs::*;
(input clk, rst_n);

  control_t ctrl;
  alu_sel_e alu_sel;

  logic [31:0] instruction;
  logic [6:0]  opcode = instruction[6:0];
  logic [2:0]  funct3 = instruction[14:12];
  logic [6:0]  funct7 = instruction[31:25];

  controller(.*);
  datapath(.*);

endmodule: cpu
