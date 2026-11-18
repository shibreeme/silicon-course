module tb;
  bit clk=0, rst=1, in_valid=0, out_ready=0;
  wire in_ready, out_valid;
  logic [31:0] a,b;
  wire signed [31:0] result;
  dot4 dut(.*);
  always #5 clk=!clk;
  logic [95:0] vectors[0:264];
  int sent=0, received=0;
  bit held=0, pending_stall=0;
  logic [31:0] saved;
  initial begin
    $readmemh("vectors.hex", vectors);
    @(negedge clk);
    if(out_valid !== 0) $fatal(1,"reset");
    rst=0;
    for(int cycle=0; cycle<4000; cycle++) begin
      if (!in_valid || !held) in_valid=(sent<265 && cycle%7!=2);
      if(sent<265) {a,b}=vectors[sent][95:32];
      out_ready=(cycle%11<6);
      @(posedge clk);
      if(saved !== result && pending_stall) $fatal(1,"unstable payload");
      if(pending_stall && out_valid !== 1) $fatal(1,"dropped valid");
      saved=result;
      pending_stall=out_valid && !out_ready;
      held=in_valid && !in_ready;
      if(out_valid && out_ready) begin
        if(received>=sent || result !== vectors[received][31:0]) $fatal(1,"mismatch %d",received);
        received++;
      end
      if(in_valid && in_ready) sent++;
      @(negedge clk);
      if(received==265) begin
        if(out_valid !== 0) $fatal(1,"duplicate output");
        $display("PASS: 265 transactions");
        $finish;
      end
    end
    $fatal(1,"timeout");
  end

endmodule

