module datapath
import definitions_pkg::*;
(input  logic        clk,
 input  logic [ 4:0] rf_w, rf_ra, rf_rb,
 input  logic        rf_wen,
 input  imm_e        imm_sel,
 input  logic [ 1:0] examux, exbmux,
 input  logic [ 1:0] wbmux,
 input  logic        br_uns,
 input  logic        aluamux, 
 input  alu_e        alu_sel,
 input  logic        drivels,
 input  logic [31:0] inst,
 input  logic [11:0] pc,
 output logic        br_eq, br_lt,
 output logic [11:0] branch_or_addr,
 inout  tri   [31:0] ls_data
);

  logic [31:0] ex_a_src;
  logic [31:0] ex_b_src;        
  logic [31:0] mem_b_src;        
  logic [31:0] id_rs1;
  logic [31:0] id_rs2;
  logic [31:0] ex_rs1;
  logic [31:0] ex_rs2;
  logic [31:0] mem_alu_out;
  logic [31:0] pre_wb_data;
  logic [31:0] wb_data;
  logic [31:0] id_imm_data;
  logic [31:0] ex_imm_data;
  logic [31:0] alu_out;     
  logic [31:0] alu_a_src;
  logic [11:2] mem_pc;
  logic [11:2] mem_next_pc;

  register_file rfile(.clk, .wen(rf_wen), .d(wb_data), .ra(rf_ra), .rb(rf_rb), .w(rf_w), .a(id_rs1), .b(id_rs2));

  // Immediate generation
  always_comb begin
    case (imm_sel)
      IMM_I_TYPE: id_imm_data = {{20{inst[31]}}, inst[31:20]};
      IMM_STORE:  id_imm_data = {{20{inst[31]}}, inst[31:25], inst[11:7]};
      IMM_BRANCH: id_imm_data = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
      IMM_JAL:    id_imm_data = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
      IMM_U_TYPE: id_imm_data = {{inst[31:12]}, 12'b0};
      default:    id_imm_data = '0;
    endcase
  end

  // ID / EX
  always_ff @(posedge clk) begin
    ex_rs1 <= id_rs1;
    ex_rs2 <= id_rs2;
    ex_imm_data <= id_imm_data;
  end

  // Branch comparator
  always_comb begin
    br_lt = '0;
    if (br_uns) br_lt = ex_a_src < ex_b_src;
    else       br_lt = signed'(ex_a_src) < signed'(ex_b_src);
  end
  assign br_eq = ex_a_src == ex_b_src;

  always_comb begin
    case (examux)
      2'b00: ex_a_src = ex_rs1;
      2'b01: ex_a_src = mem_alu_out;
      2'b10: ex_a_src = wb_data;
      2'b11: ex_a_src = '0; // lui
    endcase
  end

  always_comb begin
    case (exbmux)
      2'b00: ex_b_src = ex_rs2;
      2'b01: ex_b_src = mem_alu_out;
      2'b10: ex_b_src = wb_data;
      2'b11: ex_b_src = ex_imm_data;
    endcase
  end

  assign alu_a_src = aluamux ? {'0, pc} : ex_a_src;

  alu alu(.a(alu_a_src), .b(ex_b_src), .sel(alu_sel), .result(alu_out));

  // EX / MEM
  always_ff @(posedge clk) begin
    mem_alu_out <= alu_out;
    mem_b_src <= ex_b_src;
    mem_pc <= pc;
  end

  assign branch_or_addr = mem_alu_out[11:0];
  // Recalculate PC + 4 in MEM stage
  assign mem_next_pc = mem_pc[11:2] + 1;

  always_comb begin
    case (wbmux)
      2'b00:   pre_wb_data = ls_data;
      2'b01:   pre_wb_data = mem_alu_out;
      2'b10:   pre_wb_data = mem_next_pc;
      default: pre_wb_data = '0;
    endcase
  end

  // MEM / WB
  always_ff @(posedge clk) begin
    wb_data <= pre_wb_data;
  end

  assign ls_data = drivels ? mem_b_src : 'z;

endmodule: datapath

