/***********************************************************************
   top level cpu 
 ***********************************************************************/

module cpu
 import control_defs::*;
(input clk);

  control_t ctrl;

  logic [31:0] instruction;
  logic [6:0]  opcode = instruction[6:0];
  logic [2:0]  funct3 = instruction[14:12];
  logic [6:0]  funct7 = instruction[31:25];

  controller(.*);
  datapath(.*);

endmodule: cpu
