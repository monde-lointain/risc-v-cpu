/***********************************************************************
   common definitions 
 ***********************************************************************/
`ifndef CONTROL_DEFS_SV
`define CONTROL_DEFS_SV

package control_defs;
  typedef enum logic [3:0] {
    AND   = 4'b0000,
    OR    = 4'b0001,
    ADD   = 4'b0010,
    SUB   = 4'b0110,
    XXX   =  'x
  } alu_sel_e;

  typedef struct {
    logic     alu_src;
    logic     mem_to_reg;
    logic     reg_write;  
    logic     mem_read;   
    logic     mem_write;
    logic     branch; 
  } control_t;
endpackage: control_defs

`endif // CONTROL_DEFS_SV
