/***********************************************************************
   instruction memory 
 ***********************************************************************/

module instruction_memory
(input  logic [31:0] addr,
 output logic [31:0] data
);

 logic [31:0] mem [0:1023];

 assign data = mem[addr[31:2]];

endmodule: instruction_memory
