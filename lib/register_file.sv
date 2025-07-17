/***********************************************************************
   32x32 register file with two read ports and one write port 
 ***********************************************************************/

module register_file
(input  logic        clk, write_en,  
 input  logic [31:0] write_data, 
 input  logic [ 4:0] write_ptr,
 input  logic [ 4:0] read_a_ptr,
 input  logic [ 4:0] read_b_ptr,
 output logic [31:0] a, b 
);

  logic [31:0] registers [31:0]; // 32 registers, each 32 bits long

  // Write to the register file
  always_ff @(posedge clk) begin
    if (write_en && write_ptr != 0)
      registers[write_ptr] <= write_data;
  end

  // Register 0 is hardwired to zero
  assign a = !read_a_ptr ? 0 : registers[read_a_ptr];
  assign b = !read_b_ptr ? 0 : registers[read_b_ptr];

endmodule: register_file
