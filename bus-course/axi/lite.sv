module lite_master(input wire clk,rst_n,start,write_cmd,
  input wire [31:0] addr,data, input wire [3:0] strobe,
  output reg busy,done, output reg [31:0] result, output reg [1:0] status,
  output reg av, wv, br, arv, rr, input wire ar,wr,bv,arr,rv,
  output reg [31:0] awaddr,wdata,araddr, output reg [3:0] wstrb,
  input wire [31:0] rdata,input wire [1:0] bresp,rresp);
  always @(posedge clk) begin
    if(!rst_n) begin
      busy<=0;done<=0;av<=0;wv<=0;br<=0;arv<=0;rr<=0;
      result<=0;status<=0;awaddr<=0;araddr<=0;wdata<=0;wstrb<=0;
    end else begin
      done<=0;
      if(start && !busy) begin
        busy<=1;
        if(write_cmd) begin
          av<=1;wv<=1;br<=1;awaddr<=addr;wdata<=data;wstrb<=strobe;
        end else begin arv<=1;rr<=1;araddr<=addr;end
      end
      if(av && ar) av<=0;
      if(wv && wr) wv<=0;
      if(arv && arr) arv<=0;
      if(br && bv) begin br<=0;busy<=0;done<=1;status<=bresp;end
      if(rr && rv) begin rr<=0;busy<=0;done<=1;result<=rdata;status<=rresp;end
    end
  end
endmodule

module lite_regs(input wire clk,rst_n,input wire av,wv,br,arv,rr,
  output wire ar,wr,arr,output reg bv,rv,
  input wire [31:0] awaddr,wdata,araddr,input wire [3:0] wstrb,
  output reg [31:0] rdata,output reg [1:0] bresp,rresp);
  reg have_a,have_w; reg [31:0] a,d,value; reg [3:0] mask;
  integer i;
  assign ar=!have_a && !bv;
  assign wr=!have_w && !bv;
  assign arr=!rv;
  always @(posedge clk) begin
    if(!rst_n) begin
      have_a<=0;have_w<=0;bv<=0;rv<=0;value<=0;rdata<=0;bresp<=0;rresp<=0;
    end else begin
      if(av && ar) begin have_a<=1;a<=awaddr;end
      if(wv && wr) begin have_w<=1;d<=wdata;mask<=wstrb;end
      if(have_a && have_w) begin
        have_a<=0;have_w<=0;bv<=1;bresp<=(a==0)?0:2;
        if(a==0) for(i=0;i<4;i=i+1)
          if(mask[i]) value[i*8+:8]<=d[i*8+:8];
      end
      if(bv && br) bv<=0;
      if(arv && arr) begin rv<=1;rresp<=(araddr==0)?0:2;rdata<=(araddr==0)?value:0;end
      if(rv && rr) rv<=0;
    end
  end
endmodule
