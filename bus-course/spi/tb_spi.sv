module tb_spi;
    bit clk;
    always #5 clk = ~clk;
    logic rst=1,start=0;
    logic [7:0] tx,reply;
    wire [7:0] rx,received;
    wire miso,mosi,sck,cs_n,busy,done;
    spi_controller controller(.*);
    spi_peripheral peripheral(.*);
    integer edges;
    always @(posedge sck) if (!cs_n) begin
        if (mosi !== tx[7-edges] || miso !== reply[7-edges]) $fatal(1,"wire order");
        edges = edges+1;
    end
    initial begin
        repeat(2) @(negedge clk);
        rst=0;
        for(integer n=0;n<256;n=n+1) begin
            tx=n; reply=8'h5b ^ n; edges=0; start=1;
            @(negedge clk); start=0;
            wait(done); @(negedge clk);
            if(edges!=8 || rx!==reply || received!==tx || sck!==0 ||
               cs_n!==1 || miso!==1'bz || busy!==0) $fatal(1,"frame mismatch");
        end
        $display("PASS: 256 full-duplex frames"); $finish;
    end
    initial #60000 $fatal(1,"timeout");
endmodule
