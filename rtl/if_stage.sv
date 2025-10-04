module if_stage
(input  logic clk, rst_n, taken, halting, imem_nwr, imem_ncs,
 input  logic [9:0] br_addr,
 input  logic [31:0] imem_din,
 output logic [31:0] inst
);
  logic [9:0] pc;

  pc_mux pc_mux (.*);
  imem imem(.clk, .nwr(imem_nwr), .ncs(imem_ncs), .addr(pc), .din(imem_din), .dout(inst));
  
endmodule: if_stage
