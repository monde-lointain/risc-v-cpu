/***********************************************************************
   immediate generator
 ***********************************************************************/

module imm_gen
(input  logic [31:0] inst, 
 output logic [31:0] imm
);

  logic inst5;
  assign inst5 = inst[5];
  logic inst6;
  assign inst6 = inst[6];
  logic [11:0] imm_load;
  assign imm_load = inst[31:20];
  logic [11:0] imm_store;
  assign imm_store = {inst[31:25], inst[11:7]};
  logic [12:0] imm_branch;
  assign imm_branch = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};

  always_comb begin
    case ({inst6, inst5}) inside
      // Load
      2'b00:   imm = {{20{imm_load[11]}}, imm_load};
      // Store
      2'b01:   imm = {{20{imm_store[11]}}, imm_store};
      // Branch
      default: imm = {{19{imm_branch[12]}}, imm_branch};
    endcase
  end

endmodule: imm_gen

