/***********************************************************************
   common definitions 
 ***********************************************************************/
`ifndef DEFINITIONS_PKG_SV
`define DEFINITIONS_PKG_SV

package definitions_pkg;
  typedef enum logic [3:0] { ALU_ADD, 
                             ALU_SUB, 
                             ALU_SLL, 
                             ALU_SLT, 
                             ALU_SLTU,
                             ALU_XOR, 
                             ALU_SRL, 
                             ALU_SRA, 
                             ALU_OR, 
                             ALU_AND, 
                             ALU_LUI, 
                             ALU_XXX = 'x } alu_e;

  typedef enum logic [2:0] { IMM_I_TYPE, 
                             IMM_STORE, 
                             IMM_BRANCH, 
                             IMM_JAL, 
                             IMM_U_TYPE, 
                             IMM_XXX = 'x } imm_e;
endpackage: definitions_pkg

`endif // DEFINITIONS_PKG_SV
