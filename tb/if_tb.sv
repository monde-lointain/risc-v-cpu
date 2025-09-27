`timescale 1ns/1ps

module if_stage_tb;
  // clock and reset
  logic clk;
  logic rst_n;

  // branch and control
  logic taken;
  logic halting;
  logic [9:0] br_addr;

  // output
  logic [31:0] inst;

  // DUT
  if_stage dut (
    .clk(clk),
    .rst_n(rst_n),
    .taken(taken),
    .halting(halting),
    .br_addr(br_addr),
    .inst(inst)
  );

  // clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // preload instruction memory
  initial begin
    // simple program: inst[pc] = pc * 4
    for (int i = 0; i < 1024; i++) begin
      dut.imem.mem[i] = i * 32'h4;
    end
  end

  // stimulus
  initial begin
    rst_n = 0;
    taken = 0;
    halting = 0;
    br_addr = 0;

    #12 rst_n = 1;  // release reset

    // normal increment
    repeat (4) @(posedge clk);

    // branch taken
    @(posedge clk);
    taken = 1;
    br_addr = 10'd100;

    @(posedge clk);
    taken = 0; // back to sequential

    repeat (3) @(posedge clk);

    // halt PC
    halting = 1;
    repeat (3) @(posedge clk);
    halting = 0;

    repeat (5) @(posedge clk);

    $finish;
  end

  // monitor
    initial begin
    $display("%-8s %-6s %-6s %-8s %-8s %-6s %-10s",
             "Time", "rst_n", "taken", "halting", "br_addr", "pc", "inst");
    $monitor("%-8t %-6b %-6b %-8b %-8d %-6d %-10d",
             $time, rst_n, taken, halting, br_addr, dut.pc_mux.pc, inst);
  end

endmodule

