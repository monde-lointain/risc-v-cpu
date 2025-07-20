/***********************************************************************
   data memory 
 ***********************************************************************/

module data_memory
(input  logic        clk, mem_read, mem_write,
 input  logic [31:0] addr, write_data,
 output logic [31:0] read_data
);

  logic [31:0] mem [0:1023];
 
  assign read_data = mem_read ? mem[addr] : 'x;

  always_ff @(posedge clk)
    mem[addr] <= mem_write ? write_data : 'x;

endmodule: data_memory
