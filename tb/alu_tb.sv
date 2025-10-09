module alu_tb;

  import definitions_pkg::*;
 
  // DUT interface
  logic [31:0] a, b;
  alu_e        alu_sel;
  logic [31:0] result;
 
  alu dut (.*);
 
  // Coverage for operations
  covergroup op_cov;
    coverpoint alu_sel {
      bins basic_ops[] = {ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
                          ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND, ALU_LUI};
      ignore_bins reserved = {ALU_XXX};
    }
  endgroup
 
  // Coverage for data values
  covergroup data_cov;
    coverpoint a {
      bins zero = {32'h0000_0000};
      bins ones = {32'hFFFF_FFFF};
      bins others = {[32'h0000_0001 : 32'hFFFE_FFFF]};
    }
 
    coverpoint b {
      bins zero = {32'h0000_0000};
      bins ones = {32'hFFFF_FFFF};
      bins others = {[32'h0000_0001 : 32'hFFFE_FFFF]};
    }
 
    coverpoint alu_sel {
      bins valid_ops[] = {ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
                          ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND, ALU_LUI};
      ignore_bins invalid_ops = {ALU_XXX};
    }
 
    cross a, b, alu_sel {
      ignore_bins ignore_invalid_ops = binsof(alu_sel) intersect {ALU_XXX};
    }
  endgroup
 
  op_cov   oc;
  data_cov dc;
 
  initial begin
    oc = new();
    dc = new();
  end
 
  // Generate random data and operations
  function automatic alu_e get_op();
    int sel = $urandom_range(0, 10);
    case (sel)
     0:       return ALU_ADD;
     1:       return ALU_SUB;
     2:       return ALU_SLL;
     3:       return ALU_SLT;
     4:       return ALU_SLTU;
     5:       return ALU_XOR;
     6:       return ALU_SRL;
     7:       return ALU_SRA;
     8:       return ALU_OR;
     9:       return ALU_AND;
     10:      return ALU_LUI;
     default: return ALU_XXX;
    endcase
  endfunction
 
  function automatic logic [31:0] get_data();
    int choice = $urandom_range(0, 2);
    case (choice)
     0:       return 32'h0000_0000;
     1:       return 32'hFFFF_FFFF;
     default: return $urandom;
    endcase
  endfunction
 
  // Scoreboard to check correctness
  task check_result(input logic [31:0] a, b, input alu_e sel, input logic [31:0] dut_result);
    logic [31:0] expected;
    case (sel)
      ALU_ADD:  expected = a + b;
      ALU_SUB:  expected = a - b;
      ALU_SLL:  expected = a << b;
      ALU_SLT:  expected = signed'(a) < signed'(b);
      ALU_SLTU: expected = a < b;
      ALU_XOR:  expected = a ^ b;
      ALU_SRL:  expected = a >> b;
      ALU_SRA:  expected = a >>> b;
      ALU_OR:   expected = a | b;
      ALU_AND:  expected = a & b;
      ALU_LUI:  expected = b;
      default:  expected = 0;
    endcase
    if (dut_result !== expected)
      $error("FAIL: a=%h b=%h op=%s result=%h expected=%h", a, b, sel.name(), dut_result, expected);
  endtask
 
  // Main test process
  initial begin : test
    repeat (1000) begin
      a = get_data();
      b = get_data();
      alu_sel = get_op();
      #1;
      check_result(a, b, alu_sel, result);
      oc.sample();
      dc.sample();
    end
    $display("Simulation completed");
    $stop;
  end : test
 
endmodule : alu_tb
