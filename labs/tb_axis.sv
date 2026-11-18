module tb_axis;
    bit clk = 0;
    always #5 clk = ~clk;
    logic rst, s_valid, s_last, s_ready, m_valid, m_last, m_ready;
    logic [63:0] s_data;
    logic signed [31:0] m_data;
    axis_dot4 dut(.*);
    task tick;
        @(posedge clk);
        @(negedge clk);
    endtask
    initial begin
        rst=1; s_valid=0; s_last=0; s_data=0; m_ready=0;
        tick();
        rst=0; s_valid=1; s_data=64'h01010101_01010101;
        tick();
        s_last=1; s_data=64'h80808080_80808080;
        repeat (3) begin
            if ({s_ready,m_valid,m_last} !== 3'b010 || m_data !== 4) $fatal(1,"stalled payload");
            tick();
        end
        m_ready=1;
        tick();
        s_valid=0; s_last=0; m_ready=0;
        tick();
        if ({m_valid,m_last} !== 2'b11 || m_data !== 65536) $fatal(1,"stalled last");
        m_ready=1;
        tick();
        if (m_valid !== 0) $fatal(1,"frame did not drain");
        $display("PASS: two-beat frame and stalled TLAST");
        $finish;
    end
endmodule
