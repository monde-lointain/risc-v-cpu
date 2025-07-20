/***********************************************************************
   data memory 
 ***********************************************************************/

module data_memory
(input  logic clk,
 input  logic mem_read, mem_write,
 input  logic [31:0] addr, write_data,
 output logic [31:0] read_data
);

 logic [31:0] mem [0:1023];

 assign read_data = mem_read ? mem[addr] : 'z;

 always @(posedge clk)
   if (mem_write) mem[addr] <= write_data;

endmodule: data_memory
