module datapath_tb;

  import definitions_pkg::*;

  // Clock and DUT signals
  logic        clk;
  logic [ 4:0] rf_w, rf_ra, rf_rb;
  logic        rf_wen;
  logic        wben;
  imm_e        imm_sel;
  logic [ 1:0] examux, exbmux;
  logic        br_un;
  logic        drivels;
  logic        aluamux;
  alu_e        alu_sel;
  logic [31:0] inst;
  logic [12:0] next_pc;
  logic        br_eq, br_lt;
  logic [11:0] branch_or_addr;
  tri   [31:0] ls_data;

  // Internal test variables
  logic [31:0] exp_result;
  logic [31:0] ls_data_drv;
  assign ls_data = drivels ? ls_data_drv : 'z;

  // DUT instance
  datapath dut (.*);

  // Clock generation
  initial begin
    clk = 0;
    forever begin
       #10;
       clk = ~clk;
    end
  end

  // Transaction class
  class datapath_txn;
    rand logic [4:0] rf_w, rf_ra, rf_rb;
    rand logic       rf_wen, wben;
    rand imm_e       imm_sel;
    rand logic [1:0] examux, exbmux;
    rand logic       br_un, drivels, aluamux;
    rand alu_e       alu_sel;
    rand logic [31:0] inst;
    rand logic [12:0] next_pc;
    rand logic [31:0] a_in, b_in;

    constraint valid_enum_c {
      alu_sel inside {ALU_ADD, ALU_SUB, ALU_XOR, ALU_OR, ALU_AND,
                      ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU, ALU_LUI};
      imm_sel inside {IMM_I_TYPE, IMM_STORE, IMM_BRANCH, IMM_JAL, IMM_U_TYPE};
    }
  endclass

  // Scoreboard: computes expected result
  task automatic compute_expected(
    input datapath_txn t,
    output logic [31:0] expected
  );
    case (t.alu_sel)
      ALU_ADD:  expected = t.a_in + t.b_in;
      ALU_SUB:  expected = t.a_in - t.b_in;
      ALU_SLL:  expected = t.a_in << t.b_in;
      ALU_SLT:  expected = signed'(t.a_in) < signed'(t.b_in);
      ALU_SLTU: expected = t.a_in < t.b_in;
      ALU_XOR:  expected = t.a_in ^ t.b_in;
      ALU_SRL:  expected = t.a_in >> t.b_in;
      ALU_SRA:  expected = t.a_in >>> t.b_in;
      ALU_OR:   expected = t.a_in | t.b_in;
      ALU_AND:  expected = t.a_in & t.b_in;
      ALU_LUI:  expected = t.b_in;
    endcase
  endtask

  // Coverage
  covergroup cg @(posedge clk);
    coverpoint alu_sel;
    coverpoint imm_sel;
    coverpoint examux;
    coverpoint exbmux;
    coverpoint aluamux;
    coverpoint wben;
    coverpoint rf_wen;
  endgroup
  cg cov = new();

  // Main test process
  int pass_count = 0, fail_count = 0;
  datapath_txn t;

  initial begin
    // Initialize inputs
    rf_wen = 0; wben = 0; drivels = 0;
    alu_sel = ALU_ADD; imm_sel = IMM_I_TYPE;
    examux = 0; exbmux = 0; aluamux = 0;
    rf_w = 0; rf_ra = 0; rf_rb = 0; next_pc = 0; inst = 0;
    ls_data_drv = 0;

    repeat (1000) begin
      t = new();
      assert(t.randomize());

      // Apply random stimulus
      rf_w     = t.rf_w;
      rf_ra    = t.rf_ra;
      rf_rb    = t.rf_rb;
      rf_wen   = t.rf_wen;
      wben     = t.wben;
      imm_sel  = t.imm_sel;
      examux   = t.examux;
      exbmux   = t.exbmux;
      br_un    = t.br_un;
      drivels  = t.drivels;
      aluamux  = t.aluamux;
      alu_sel  = t.alu_sel;
      inst     = t.inst;
      next_pc  = t.next_pc;
      ls_data_drv = $urandom();

      compute_expected(t, exp_result);

      // Wait one cycle for computation
      @(posedge clk);

      // Check branch comparator only (since ALU output not directly exposed)
      if (dut.br_eq !== (t.a_in == t.b_in))
        $error("Mismatch in br_eq at iteration %0d", pass_count + fail_count);
      if (dut.br_lt !== ((t.br_un) ? (t.a_in < t.b_in)
                                   : ($signed(t.a_in) < $signed(t.b_in))))
        $error("Mismatch in br_lt at iteration %0d", pass_count + fail_count);

      // Coverage sample
      cov.sample();

      pass_count++;
    end

    $display("----------------------------------------------------");
    $display("Random test completed: %0d passes, %0d fails", pass_count, fail_count);
    $display("Functional coverage: %0.2f%%", cov.get_inst_coverage());
    $display("----------------------------------------------------");
    $finish;
  end

endmodule: datapath_tb
