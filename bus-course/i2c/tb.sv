module tb;
 bit clk=0; always #5 clk=!clk;
 bit rst=1,start=0; reg [6:0] addr; reg [7:0] data;
 reg [3:0] divider=0; always @(posedge clk) divider<=divider+1'b1;
 wire scl_low,md,sd,busy,done,nack,written;wire [7:0] value;
 tri1 scl,sda;
 assign scl=scl_low?1'b0:1'bz;
 assign sda=md?1'b0:1'bz;
 assign sda=sd?1'b0:1'bz;
 i2c_writer writer(clk,rst,&divider,start,addr,data,sda,scl_low,md,busy,done,nack);
 i2c_sink sink(clk,rst,scl,sda,sd,written,value);
 integer writes=0;
 always @(posedge clk) if(written) writes<=writes+1;
 task send(input [6:0] a,input [7:0] d,input bit reject);
 integer before_count;
 begin
   before_count=writes; @(negedge clk);addr=a;data=d;start=1;
   @(negedge clk);start=0;wait(done);@(negedge clk);
   if(nack!==reject || writes!=before_count+!reject || (!reject && value!==d) || sda!==1 || scl!==1)
     $fatal(1,"write %h %h",a,d);
 end endtask
 initial begin repeat(5) @(negedge clk);rst=0;
 send('h48,'ha5,0);send('h49,'h12,1);send('h48,'h00,0);send('h48,'hff,0);
 $display("PASS: I2C three writes and address NACK");$finish; end
 initial #1000000 $fatal(1,"timeout");
endmodule
