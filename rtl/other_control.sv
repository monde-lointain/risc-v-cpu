/***********************************************************************
   controls various signals for the datapath 
 ***********************************************************************/

module other_control
 import control_defs::*;
(input  logic [6:0] opcode,
 output control_t   ctrl,
 output logic [1:0] alu_op 
);
  typedef enum logic [6:0] {
    OP_RTYPE = 7'b0110011,
    OP_LW    = 7'b0000011,
    OP_SW    = 7'b0100011,
    OP_BEQ   = 7'b1100011,
    OP_XXX   = 'x
  } opcode_t;

  always_comb begin
    ctrl = '{default:0};
    alu_op = '0;
    case (opcode)
      OP_RTYPE: begin
        ctrl.reg_write  = 1;
        alu_op          = 2'b10;
      end
      OP_LW: begin
        ctrl.alu_src    = 1;
        ctrl.mem_to_reg = 1;
        ctrl.reg_write  = 1;
        ctrl.mem_read   = 1;
        alu_op          = 2'b00;
      end
      OP_SW: begin
        ctrl.alu_src    = 1;
        ctrl.mem_write  = 1;
        alu_op          = 2'b00;
      end
      OP_BEQ: begin
        ctrl.branch     = 1;
        alu_op          = 2'b01;
      end
      default: begin
        ctrl   = '{default:'x};
        alu_op = 'x;
      end
    endcase
  end

endmodule: other_control
