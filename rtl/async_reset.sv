/***********************************************************************
   reset synchronizer for the rest of the circuit
 ***********************************************************************/

module async_reset
(input  logic clk, asyncrst_n,
 output logic rst_n
);

  logic rff1;

  always_ff @(posedge clk or negedge asyncrst_n) 
    if (!asyncrst_n) {rst_n, rff1} <= '0;
    else             {rst_n, rff1} <= {rff1, '1};

endmodule: async_reset
