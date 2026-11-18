module dot4(input logic clk, rst, in_valid, output logic in_ready,
            input logic [31:0] a, b, output logic out_valid,
            input logic out_ready, output logic signed [31:0] result);
  // Lane zero occupies bits [7:0]. All four products belong to one transaction.
  logic signed [15:0] product [0:3];
  for (genvar k=0; k<4; k=k+1) begin : lanes
    assign product[k] = $signed(a[8*k+:8]) * $signed(b[8*k+:8]);
  end
  assign in_ready = !rst && (!out_valid || out_ready);
  always_ff @(posedge clk) begin
    if (rst) begin
      out_valid <= 0;
      result <= 0;
    end else if (in_ready) begin
      out_valid <= in_valid;
      if (in_valid)
        result <= product[0]+product[1]+product[2]+product[3];
    end
  end
endmodule
