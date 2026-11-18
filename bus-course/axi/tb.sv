module tb;
  bit clk; always #5 clk=~clk;
  bit rst_n,start,write_cmd;bit [31:0] addr,data;bit [3:0] strobe;
  wire busy,done;wire [31:0] result;wire [1:0] status;
  wire av,wv,br,arv,rr,ar,wr,bv,arr,rv;
  wire [31:0] awaddr,wdata,araddr,rdata;wire [3:0] wstrb;wire [1:0] bresp,rresp;
  bit ga,gw,gb,gr;wire sa,sw,sb,sr;
  assign ar=sa && ga; assign wr=sw && gw;
  assign bv=sb && gb; assign rv=sr && gr;
  lite_master m(.*);
  lite_regs s(.av(av && ga),.wv(wv && gw),.ar(sa),.wr(sw),.bv(sb),
    .br(br && gb),.rv(sr),.rr(rr && gr),.*);
  task tick; @(negedge clk); endtask
  task command(input bit we,input [31:0] address,payload,input [3:0] mask);
    write_cmd=we;addr=address;data=payload;strobe=mask;start=1;tick();start=0;
  endtask
  task testwrite(input bit addr_first,input [31:0] address,payload,input [3:0] mask,input [1:0] response);
    ga=addr_first;gw=!addr_first;gb=0;
    command(1,address,payload,mask);
    repeat(3) tick();
    if(av!==!addr_first || wv!==addr_first || sb!==0) $fatal(1,"independence");
    ga=1;gw=1;repeat(4) tick();
    repeat(3) begin if(sb!==1 || bresp!==response || done!==0) $fatal(1,"B stall");tick();end
    gb=1;tick();if(done!==1 || status!==response) $fatal(1,"B completion");
  endtask
  task testread(input [31:0] address,expected,input [1:0] response);
    gr=0;command(0,address,0,0);tick();
    repeat(3) begin if(sr!==1 || rdata!==expected || rresp!==response) $fatal(1,"R stall");tick();end
    gr=1;tick();if(done!==1 || result!==expected || status!==response) $fatal(1,"R completion");
  endtask
  initial begin
    tick();rst_n=1;testread(0,0,0);
    testwrite(1,0,'h11223344,15,0); testwrite(0,0,'haabbccdd,5,0);
    testread(0,'h11bb33dd,0);testwrite(0,4,0,15,2);testread(4,0,2);
    testread(0,'h11bb33dd,0);$display("PASS AXI-Lite: split writes, stalls, strobes, errors");$finish;
  end
  initial #3000 $fatal(1,"timeout");
endmodule
