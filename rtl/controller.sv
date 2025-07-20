/***********************************************************************
   control unit 
 ***********************************************************************/

module controller
 import control_defs::*;
(input  logic [6:0] opcode,
 input  logic [2:0] funct3,
 input  logic [6:0] funct7,
 output control_t   ctrl,
 output alu_sel_e   alu_sel
);

  logic [1:0] alu_op;
  other_control other_ctrl(.*);
  alu_control alu_ctrl(.*);

endmodule: controller
