/***********************************************************************
   32x32 register file with two read ports and one write port 
 ***********************************************************************/

module register_file
(input  logic        clk, wen,  
 input  logic [31:0] d, 
 input  logic [ 4:0] ra, rb, w,
 output logic [31:0] a, b 
);

  logic [31:0] regs [31:0]; // 32 regs, each 32 bits long

  // Write to the register file
  always_ff @(posedge clk) 
    if (wen) regs[w] <= d;

  // Register 0 is hardwired to zero
  assign a = !ra ? 0 : regs[ra];
  assign b = !rb ? 0 : regs[rb];

endmodule: register_file
