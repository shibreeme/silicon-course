// One 64-bit AXI4-Stream beat holds a complete dot product.
// Fixed eight-byte input beats and four-byte output beats, no partial beats.
module axis_dot4(
    input logic clk, rst,
    input logic s_valid, s_last,
    output logic s_ready,
    input logic [63:0] s_data,
    output logic m_valid, m_last,
    input logic m_ready,
    output logic signed [31:0] m_data
);
    dot4 core (.clk(clk), .rst(rst), .in_valid(s_valid), .in_ready(s_ready),
               .a(s_data[31:0]), .b(s_data[63:32]), .out_valid(m_valid),
               .out_ready(m_ready), .result(m_data));

    always_ff @(posedge clk) begin
        if (rst)
            m_last <= 1'b0;
        else if (s_valid && s_ready)
            m_last <= s_last;
    end
endmodule
