module register_file_tb;

  // DUT interface signals
  logic        clk;
  logic        wen;
  logic [31:0] d;
  logic [ 4:0] ra, rb, w;
  logic [31:0] a, b;

  // Instantiate DUT
  register_file dut (.*);

  initial begin
    clk = 0;
    forever begin
       #10;
       clk = ~clk;
    end
  end

  logic [31:0] ref_regs [31:0];

  task update_ref_model();
    if (wen) ref_regs[w] = d;
  endtask

  task check_outputs();
    logic [31:0] exp_a, exp_b;
    exp_a = (ra == 0) ? 0 : ref_regs[ra];
    exp_b = (rb == 0) ? 0 : ref_regs[rb];
    if (a !== exp_a)
      $error("FAILED (register a): expected %0h, got %0h, ra=%0d", exp_a, a, ra);
    if (b !== exp_b)
      $error("FAILED (register b): expected %0h, got %0h, rb=%0d", exp_b, b, rb);
  endtask

  class regfile_txn;
    rand logic        wen;
    rand logic [31:0] d;
    rand logic [ 4:0] ra, rb, w;
  endclass

  regfile_txn txn;

  covergroup regfile_cg @(posedge clk);
    wen: coverpoint txn.wen;
    ra: coverpoint txn.ra;
    rb: coverpoint txn.rb;
    w: coverpoint txn.w;
    cross wen, w;
  endgroup

  regfile_cg cg = new();

  initial begin: tester
    clk = 0;
    wen = 0;
    d   = 0;
    ra  = 0;
    rb  = 0;
    w   = 0;

    txn = new();

    repeat (1000) begin
      assert(txn.randomize());
      wen = txn.wen;
      d   = txn.d;
      ra  = txn.ra;
      rb  = txn.rb;
      w   = txn.w;

      @(posedge clk);
      update_ref_model();
      @(negedge clk);
      check_outputs();
      cg.sample();
    end

    $display("Simulation completed");
    $finish;
  end: tester

endmodule: register_file_tb

