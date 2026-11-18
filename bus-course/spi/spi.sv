// Mode 0, eight bits, MSB first. One byte per asserted CS.
module spi_controller(input logic clk, rst, start, input logic [7:0] tx,
    input logic miso, output logic sck, cs_n, mosi, busy, done, output logic [7:0] rx);
    logic [7:0] transmit, receive;
    logic [2:0] index;
    logic finish_frame;
    always_ff @(posedge clk) begin
        if (rst) begin
            sck <= 0; cs_n <= 1; busy <= 0; done <= 0;
            mosi <= 0; rx <= 0; finish_frame <= 0;
        end else begin
            done <= 0;
            if (!busy && start) begin
                transmit <= tx; receive <= 0; index <= 7; mosi <= tx[7];
                cs_n <= 0; busy <= 1;
            end else if (busy && finish_frame) begin
                cs_n <= 1; busy <= 0; done <= 1; rx <= receive; finish_frame <= 0;
            end else if (busy && !sck) begin
                sck <= 1; receive <= {receive[6:0],miso};
            end else if (busy) begin
                sck <= 0;
                if (index == 0) finish_frame <= 1;
                else begin index <= index-1'b1; mosi <= transmit[index-1'b1]; end
            end
        end
    end
endmodule

// Keep reply stable from before CS assertion until CS deassertion.
module spi_peripheral(input logic sck, cs_n, mosi, input logic [7:0] reply,
    output wire miso, output logic [7:0] received);
    logic [2:0] index;
    always_ff @(negedge sck or posedge cs_n)
        if (cs_n) index <= 7;
        else index <= index-1'b1;
    assign miso = cs_n ? 1'bz : reply[index];
    always_ff @(posedge sck)
        if (!cs_n) received <= {received[6:0],mosi};
endmodule
