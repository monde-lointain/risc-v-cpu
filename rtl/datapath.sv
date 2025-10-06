module datapath
import definitions_pkg::*;
(input  logic        clk,
 input  logic [ 4:0] rf_w, rf_ra, rf_rb,
 input  logic        rf_wen,
 input  logic        wben,
 input  imm_e        imm_sel,
 input  logic [ 1:0] examux, exbmux,
 input  logic        br_un,
 input  logic        drivels,
 input  logic        aluamux, 
 input  alu_e        alu_sel,
 input  logic [31:0] inst,
 input  logic [12:0] next_pc,
 output logic        br_eq, br_lt,
 output logic [11:0] branch_or_addr,
 inout  logic [31:0] ls_data
);

  logic [31:0] ex_a_src;
  logic [31:0] ex_b_src;        
  logic [31:0] mem_b_src;        
  logic [31:0] id_rs1;
  logic [31:0] id_rs2;
  logic [31:0] ex_rs1;
  logic [31:0] ex_rs2;
  logic [31:0] mem_alu_out;
  logic [31:0] wb_data;
  logic [31:0] id_imm_data;
  logic [31:0] ex_imm_data;
  logic [31:0] alu_out;     
  logic [31:0] alu_a_src;

  assign ls_data = drivels ? mem_b_src : 'Z;
  assign branch_or_addr = mem_alu_out[11:0];
  assign alu_a_src = aluamux ? {'0, next_pc} : ex_a_src;

  imm_gen imm_gen(.imm_sel, .inst, .imm_data(id_imm_data));
  register_file rfile(.clk, .wen(rf_wen), .d(wb_data), .ra(rf_ra), .rb(rf_rb), .w(rf_w), .a(id_rs1), .b(id_rs2));
  alu alu(.a(alu_a_src), .b(ex_b_src), .sel(alu_sel), .result(alu_out));

  always_comb begin
    case (examux)
      2'b00: ex_a_src = ex_rs1;
      2'b01: ex_a_src = mem_alu_out;
      2'b10: ex_a_src = wb_data;
      2'b11: ex_a_src = '0; // lui
    endcase
    case (exbmux)
      2'b00: ex_b_src = ex_rs2;
      2'b01: ex_b_src = mem_alu_out;
      2'b10: ex_b_src = wb_data;
      2'b11: ex_b_src = ex_imm_data;
    endcase

    // Branch comparator
    br_eq = ex_a_src == ex_b_src;
    if (br_un)
      br_lt = ex_a_src < ex_b_src;
    else
      br_lt = signed'(ex_a_src) < signed'(ex_b_src);
  end

  always_ff @(posedge clk) begin
    // ID / EX
    ex_rs1      <= id_rs1;
    ex_rs2      <= id_rs2;
    ex_imm_data <= id_imm_data;
    // EX / MEM
    mem_alu_out <= alu_out;
    mem_b_src   <= ex_b_src;
    // MEM / WB
    wb_data     <= wben ? mem_alu_out : ls_data;
  end

endmodule: datapath

