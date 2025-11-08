/***********************************************************************
   common definitions 
 ***********************************************************************/
`ifndef DEFINITIONS_PKG_SV
`define DEFINITIONS_PKG_SV

package definitions_pkg;
  typedef enum logic [3:0] {ALU_ADD, 
                            ALU_SUB, 
                            ALU_SLL, 
                            ALU_SLT, 
                            ALU_SLTU,
                            ALU_XOR, 
                            ALU_SRL, 
                            ALU_SRA, 
                            ALU_OR, 
                            ALU_AND, 
                            ALU_XXX = 'x} alu_e;

  typedef enum logic [3:0] {BR_EQ  = 4'b0001, 
                            BR_NE  = 4'b0010, 
                            BR_LT  = 4'b0100, 
                            BR_GE  = 4'b1000,
                            BR_XXX = 'x     } branch_e; 

  typedef enum logic [2:0] {IMM_I_TYPE, 
                            IMM_STORE, 
                            IMM_BRANCH, 
                            IMM_JAL, 
                            IMM_U_TYPE, 
                            IMM_XXX = 'x} imm_e;
endpackage: definitions_pkg

`endif // DEFINITIONS_PKG_SV
