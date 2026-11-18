module tb_apb;
    bit clk;
    always #5 clk = ~clk;
    logic rst_n, cmd_valid, cmd_write, cmd_ready, done, error;
    logic [7:0] cmd_addr, paddr;
    logic [31:0] cmd_data, read_data, pwdata, prdata;
    logic psel, penable, pwrite, pready, pslverr;
    apb_requester u_req(.*);
    apb_registers u_regs(.*);
    int setups, stalls, transfers;
    logic [40:0] snapshot;
    always @(posedge clk) if (rst_n) begin
        if (psel && !penable) begin
            setups++;
            snapshot = {paddr,pwrite,pwdata};
        end
        if (penable) begin
            if (!psel || {paddr,pwrite,pwdata} !== snapshot) $fatal(1,"unstable access");
            if (pready) transfers++; else stalls++;
        end
    end
    task transact(input bit wr, input logic [7:0] addr,
                  input logic [31:0] data, expected, input bit fault);
        @(negedge clk);
        if (!cmd_ready) $fatal(1,"requester busy");
        cmd_valid=1; cmd_addr=addr; cmd_write=wr; cmd_data=data;
        @(negedge clk);
        cmd_valid=0; cmd_data=~data; cmd_addr=~addr;
        while (!done) @(negedge clk);
        if (error !== fault || (!wr && read_data !== expected))
            $fatal(1,"bad response addr=%h",addr);
    endtask
    initial begin
        rst_n=0; cmd_valid=0;
        repeat (2) @(negedge clk);
        rst_n=1;
        transact(0,0,0,0,0);
        transact(1,0,32'hcafe1234,0,0);
        transact(1,4,32'hdeadbeef,0,1);
        transact(0,8,0,0,1);
        transact(0,0,0,32'hcafe1234,0);
        transact(0,4,0,1,0);
        if (setups!=6 || stalls!=6 || transfers!=6) $fatal(1,"phase counts");
        $display("PASS APB: 6 transfers, 6 wait cycles, error and side effects checked");
        $finish;
    end
    initial #2000 $fatal(1,"timeout");
endmodule
