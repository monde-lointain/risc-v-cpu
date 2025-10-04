module pc_mux
(input  logic       clk, rst_n, taken, halting,
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
