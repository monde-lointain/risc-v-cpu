/***********************************************************************
   common definitions 
 ***********************************************************************/
`ifndef DEFINITIONS_PKG_SV
`define DEFINITIONS_PKG_SV

package definitions_pkg;
  typedef enum logic [3:0] {
    AND = 4'b0000,
    OR  = 4'b0001,
    ADD = 4'b0010,
    SUB = 4'b0110
  } opcodes_t;

  typedef struct {
    logic [31:0] a, b;
    opcodes_t    opcode_e;
  } instruction_t;
endpackage: definitions_pkg

`endif // DEFINITIONS_PKG_SV
