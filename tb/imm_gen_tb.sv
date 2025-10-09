module imm_gen_tb;

  import definitions_pkg::*;

  // DUT I/O
  logic [31:0] inst;
  imm_e        imm_sel;
  logic [31:0] imm_data;

  // DUT instance
  imm_gen dut (.*);

  // Functional coverage
  covergroup cg;
    coverpoint imm_sel {
      bins valid_bins[] = {IMM_I_TYPE, IMM_STORE, IMM_BRANCH, IMM_JAL, IMM_U_TYPE};
    }
  endgroup

  cg cov;

  initial begin
    cov = new();
  end

  function automatic imm_e get_imm_type();
    int sel = $urandom_range(0, 4);
    case (sel)
      0:       return IMM_I_TYPE;
      1:       return IMM_STORE;
      2:       return IMM_BRANCH;
      3:       return IMM_JAL;
      4:       return IMM_U_TYPE;
      default: return IMM_XXX;
    endcase
  endfunction

  // Scoreboard: computes expected immediate
  task check_result(input logic [31:0] inst, input imm_e sel, input logic [31:0] dut_result);
    logic [31:0] expected;
    logic [31:0] i_imm, s_imm, b_imm, jal_imm, u_imm;

    i_imm   = {{20{inst[31]}}, inst[31:20]};
    s_imm   = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    b_imm   = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    jal_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    u_imm   = {inst[31:12], 12'b0};

    case (sel)
      IMM_I_TYPE: expected = i_imm;
      IMM_STORE : expected = s_imm;
      IMM_BRANCH: expected = b_imm;
      IMM_JAL   : expected = jal_imm;
      IMM_U_TYPE: expected = u_imm;
      default   : expected = 'x;
    endcase
    if (dut_result !== expected)
      $error("FAIL: inst=%h imm_sel=%h imm_data=%h expected=%h", inst, sel.name(), dut_result, expected);
  endtask


  // Main stimulus process
  initial begin: test
    repeat (1000) begin
      imm_sel = get_imm_type();
      inst = $random;
      #1;
      check_result(inst, imm_sel, imm_data);
      cov.sample();
    end
    $display("Simulation completed.");
    $stop;
  end: test

endmodule: imm_gen_tb
