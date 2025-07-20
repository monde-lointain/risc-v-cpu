/***********************************************************************
   cpu datapath
 ***********************************************************************/

module datapath
 import control_defs::*;
(input  logic        clk,
 input  control_t    ctrl,
 output logic [31:0] instruction
);
  logic [31:0] pc, next_inst_pc, branch_pc;

  // Fetch next instruction
  instruction_memory imem(.addr(pc), .data(instruction));

  // Get immediate from instruction
  logic [31:0] immediate;
  imm_gen imm_gen(.inst(instruction), .imm(immediate)); 

  // Perform register file read/write
  logic [4:0]  rd  = instruction[11:7];
  logic [4:0]  rs1 = instruction[19:15];
  logic [4:0]  rs2 = instruction[24:20];
  logic [31:0] rf_write_data, rf_read_a_data, rf_read_b_data;
  register_file regfile(.clk, .write_en(ctrl.reg_write), .write_ptr(rd),
                        .read_a_ptr(rs1), .read_b_ptr(rs2), 
                        .write_data(rf_write_data), .a(rf_read_a_data), 
                        .b(rf_read_b_data));

  // Select ALU inputs
  logic [31:0] alu_a = rf_read_a_data;
  logic [31:0] alu_b = ctrl.alu_src ? rf_read_b_data : immediate;

  // Perform ALU operation
  logic [31:0] alu_result;
  logic zero;
  alu alu(.sel(ctrl.alu_sel), .a(alu_a), .b(alu_b), .result(alu_result), .zero);

  // Select next PC
  assign next_inst_pc = pc + 4;
  assign branch_pc = pc + immediate;
  logic pc_src = ctrl.branch && zero;
  always_ff @(posedge clk)
    pc <= pc_src ? next_inst_pc : branch_pc;

  // Perform data memory reads/writes
  logic [31:0] dmem_read_data;
  data_memory dmem(.clk, .mem_read(ctrl.mem_read), .mem_write(ctrl.mem_write),
                   .addr(alu_result), .write_data(rf_read_b_data), 
                   .read_data(dmem_read_data));

  // Select whether to writeback the value read from memory or the ALU result 
  assign rf_write_data = ctrl.mem_to_reg ? dmem_read_data : alu_result;

endmodule: datapath
