`timescale 1ns/1ps

module tb_pc_mux;
  logic clk;
  logic rst_n;
  logic taken;
  logic halting;
  logic [9:0] br_addr;
  logic [9:0] pc;

  // DUT
  pc_mux dut (
    .clk(clk),
    .rst_n(rst_n),
    .taken(taken),
    .halting(halting),
    .br_addr(br_addr),
    .pc(pc)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz

  // Stimulus
  initial begin
    // Initialize
    rst_n   = 0;
    taken   = 0;
    halting = 0;
    br_addr = 10'd100;

    // Reset pulse
    #12 rst_n = 1;

    // Normal increment
    repeat (3) @(posedge clk);

    // Branch taken
    taken = 1;
    @(posedge clk);
    taken = 0;

    // Hold at branch result
    repeat (2) @(posedge clk);

    // Halting
    halting = 1;
    repeat (3) @(posedge clk);
    halting = 0;

    // Resume increment
    repeat (3) @(posedge clk);

    $finish;
  end

  // Monitor
  initial begin
    $display("%-8s %-6s %-6s %-8s %-8s %-6s", "Time", "rst_n", "taken", "halting", "br_addr", "pc");
    $monitor("%-8t %-6b %-6b %-8b %-8d %-6d",
             $time, rst_n, taken, halting, br_addr, pc);
  end

endmodule

