module i2c_writer(input wire clk, rst, tick, start,
 input wire [6:0] address, input wire [7:0] data, input wire sda,
 output reg scl_low, sda_low, busy, done, nack);
 localparam IDLE=0, START=1, LOW=2, SETUP=3, HIGH=4, SAMPLE=5, STOP0=6, STOP1=7, STOP2=8, STOP3=9;
 reg [3:0] state, bit_no;
 reg [7:0] tx, payload;
 reg data_phase;
 always @(posedge clk) begin
   if(rst) begin state<=IDLE; busy<=0; done<=0; nack<=0; scl_low<=0; sda_low<=0; end
   else begin
     done<=0;
     if(state==IDLE && start) begin
       tx<={address,1'b0}; payload<=data; bit_no<=0; data_phase<=0;
       state<=START; busy<=1; nack<=0;
     end else if(tick) case(state)
       START: begin sda_low<=1; state<=LOW; end
       LOW: begin scl_low<=1; state<=SETUP; end
       SETUP: begin sda_low <= bit_no==8 ? 0 : !tx[7]; state<=HIGH; end
       HIGH: begin scl_low<=0; state<=SAMPLE; end
       SAMPLE: begin
         state<=LOW;
         if(bit_no<8) begin tx<=tx<<1; bit_no<=bit_no+1'b1; end
         else if(sda || data_phase) begin nack<=sda; state<=STOP0; end
         else begin tx<=payload; bit_no<=0; data_phase<=1; end
       end
       STOP0: begin scl_low<=1; state<=STOP1; end
       STOP1: begin sda_low<=1; state<=STOP2; end
       STOP2: begin scl_low<=0; state<=STOP3; end
       STOP3: begin sda_low<=0; busy<=0; done<=1; state<=IDLE; end
       default: ;
     endcase
   end
 end
endmodule

module i2c_sink #(parameter [6:0] ADDRESS=7'h48)
 (input wire clk,rst,scl,sda, output reg sda_low, written, output reg [7:0] value);
 reg [2:0] cs, ds;
 reg [7:0] shift;
 reg [3:0] count;
 reg active, selected, payload;
 wire rise=cs[1] && !cs[2], fall=!cs[1] && cs[2];
 always @(posedge clk) begin
   if(rst) begin cs<=7; ds<=7; active<=0; written<=0; value<=0; sda_low<=0;
     count<=0; selected<=0; payload<=0; shift<=0; end
   else begin
     cs<={cs[1:0],scl}; ds<={ds[1:0],sda}; written<=0;
     if(cs[1] && ds[2] && !ds[1]) begin active<=1; count<=0; payload<=0; selected<=0; sda_low<=0; end
     else if(cs[1] && !ds[2] && ds[1]) begin active<=0; sda_low<=0; end
     else if(active) begin
       if(rise && count<8) begin
         shift<={shift[6:0],ds[1]}; count<=count+1'b1;
         if(count==7 && !payload) selected<=({shift[6:0],ds[1]}=={ADDRESS,1'b0});
       end else if(fall && count==8) begin sda_low<=selected; count<=9; end
       else if(fall && count==9) begin
         sda_low<=0; count<=0;
         if(payload && selected) begin value<=shift; written<=1; end
         active<=selected && !payload; payload<=1;
       end
     end
   end
 end
endmodule
