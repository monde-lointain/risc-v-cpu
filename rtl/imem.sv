module imem 
(input  logic        clk,
 input  logic        nwr,  // active-low write control
 input  logic        ncs,  // active-low chip select
 input  logic [9:0]  addr,
 input  logic [31:0] din,
 output logic [31:0] dout
);

  // 1024 x 32-bit memory
  logic [31:0] mem [0:1023];

  // Synchronous read/write behavior
  always_ff @(posedge clk) begin
    if (!ncs) begin
      if (!nwr) begin
        // Write
        mem[addr] <= din;
        dout      <= din;     // write-through
      end
      else begin
        // Read
        dout <= mem[addr];
      end
    end 
  end

endmodule: imem

