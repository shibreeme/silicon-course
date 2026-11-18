module tb_burst;
    bit clk; always #5 clk=~clk;
    logic rst_n,start,busy,done,fault,arvalid,arready,rvalid,rlast,rready,take,valid;
    logic [31:0] base,araddr,rdata,sample;
    logic [7:0] len, arlen;
    logic [2:0] arsize;
    logic [1:0] arburst,rresp;
    burst_reader manager(.*);
    burst_rom responder(.*);
    integer addresses;
    always @(posedge clk) if (rst_n && arvalid && arready) addresses++;
    task check(input logic [31:0] origin,input integer count,input bit legal);
        integer seen, before_count;
        @(negedge clk); before_count=addresses;
        start=1; base=origin; len=count-1; take=0;
        @(negedge clk); start=0;
        if (!legal) begin
            if ({done,fault,busy,arvalid} !== 4'b1100) $fatal(1,"bad request accepted");
        end else begin
            if ({arvalid,arburst,arsize} !== 6'b101010 || araddr !== origin || arlen !== len)
                $fatal(1,"address descriptor");
            seen=0;
            while (seen<count) begin
                while(!valid) @(negedge clk);
                repeat(2) begin
                    if (valid!==1 || sample!==((origin+4*seen)^32'h5aa50000) ||
                        rlast!==(seen==count-1)) $fatal(1,"data or last");
                    @(negedge clk);
                end
                take=1; @(negedge clk); take=0; seen++;
            end
            if (!done || fault || addresses!=before_count+1) $fatal(1,"completion");
        end
    endtask
    initial begin
        rst_n=0; start=0; take=0;
        repeat(2) @(negedge clk); rst_n=1;
        check('h100,1,1); check('hff0,4,1); check('hff4,4,0);
        check('h002,1,0); check('h4000,256,1);
        $display("PASS AXI4 INCR read: 1/4/256 beats, stalls, alignment and 4KiB boundary");
        $finish;
    end
    initial #20000 $fatal(1,"timeout");
endmodule
