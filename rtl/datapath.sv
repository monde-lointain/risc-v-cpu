/***********************************************************************
   cpu datapath
 ***********************************************************************/

module datapath
 import definitions_pkg::*;
(input  logic        clk, write_en,
 input  opcodes_t    opcode,
 input  logic [ 4:0] write_ptr, 
 input  logic [ 4:0] read_a_ptr, 
 input  logic [ 4:0] read_b_ptr, 
 output logic [31:0] result,
 output logic        zero
);

  instruction_t iw;
  logic [31:0] a, b;

  register_file regfile (.clk, .write_en, .write_data(result), .write_ptr,
                         .read_a_ptr, .read_b_ptr, .a, .b);
  alu           alu     (.*);

  assign iw = '{a, b, opcode};

endmodule: datapath 
