module if_stage
(input  logic clk, rst_n, taken, halting,
 input  logic [9:0] br_addr,
 output logic [31:0] inst
);
  logic [9:0] pc;

  pc_mux pc_mux (.*);
  instruction_memory imem (.addr(pc), .data(inst));
  
endmodule: if_stage

module pc_mux
(input  logic clk, rst_n, taken, halting,
 input  logic [9:0] br_addr,
 output logic [9:0] pc
);

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) pc <= 0;
    else begin
      if      (halting) pc <= pc;
      else if (taken)   pc <= br_addr;
      else              pc <= pc + 10'd4;
    end
  end
endmodule

module instruction_memory
(input  logic [9:0] addr,
 output logic [31:0] data
);
  // IMEM: 32x1024 (4 KiB)
  logic [31:0] mem [0:1023];

  assign data = mem[addr];

endmodule: instruction_memory
