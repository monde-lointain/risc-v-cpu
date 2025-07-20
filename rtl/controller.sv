/***********************************************************************
   control unit 
 ***********************************************************************/

module controller
 import control_defs::*;
(input  logic [6:0] opcode,
 input  logic [2:0] funct3,
 input  logic [6:0] funct7,
 output control_t   ctrl
);

  logic [1:0] alu_op;
  other_control other_ctrl(.opcode, .alu_src(ctrl.alu_src),
                           .mem_to_reg(ctrl.mem_to_reg),
                           .reg_write(ctrl.reg_write), .mem_read(ctrl.mem_read),
                           .mem_write(ctrl.mem_write),
                           .branch(ctrl.branch),
                           .alu_op);
  alu_control alu_ctrl(.alu_op, .funct7, .funct3, .alu_sel(ctrl.alu_sel));

endmodule: controller
