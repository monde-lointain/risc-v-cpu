/***********************************************************************
   controls various signals for the datapath 
 ***********************************************************************/

module other_control
(input  logic [6:0] opcode,
 output logic       alu_src,
 output logic       mem_to_reg,
 output logic       reg_write,
 output logic       mem_read,
 output logic       mem_write,
 output logic       branch,
 output logic [1:0] alu_op 
);
  typedef enum logic [6:0] {
    OP_RTYPE = 7'b0110011,
    OP_LW    = 7'b0000011,
    OP_SW    = 7'b0100011,
    OP_BEQ   = 7'b1100111,
    OP_XXX   = 'x
  } opcode_t;

  always_comb begin
    alu_src    = '0;
    mem_to_reg = '0;
    reg_write  = '0;
    mem_read   = '0;
    mem_write  = '0;
    branch     = '0;
    alu_op     = '0;
    case (opcode)
      OP_RTYPE: begin
        reg_write  = 1;
        alu_op     = 2'b10;
      end
      OP_LW: begin
        alu_src    = 1;
        mem_to_reg = 1;
        reg_write  = 1;
        mem_read   = 1;
        alu_op     = 2'b00;
      end
      OP_SW: begin
        alu_src    = 1;
        mem_write  = 1;
        alu_op     = 2'b00;
      end
      OP_BEQ: begin
        branch     = 1;
        alu_op     = 2'b01;
      end
      default: begin
        alu_src    = 'x;
        mem_to_reg = 'x;
        reg_write  = 'x;
        mem_read   = 'x;
        mem_write  = 'x;
        branch     = 'x;
        alu_op     = 'x;
      end
    endcase
  end

endmodule: other_control
