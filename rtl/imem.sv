module instruction_memory
(input  logic [9:0] addr,
 output logic [31:0] data
);
  // IMEM: 32x1024 (4 KiB)
  logic [31:0] mem [0:1023];

  assign data = mem[addr];

endmodule: instruction_memory
