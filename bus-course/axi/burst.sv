module burst_reader(
    input logic clk, rst_n, start,
    input logic [31:0] base, input logic [7:0] len,
    output logic busy, done, fault,
    output logic [31:0] araddr, output logic [7:0] arlen,
    output logic [2:0] arsize, output logic [1:0] arburst,
    output logic arvalid, input logic arready,
    input logic [31:0] rdata, input logic [1:0] rresp,
    input logic rvalid, rlast, output logic rready,
    input logic take, output logic valid, output logic [31:0] sample
);
    logic receiving;
    logic [7:0] remaining;
    // Exclusive byte end within the current 4 KiB page; 4096 is legal.
    wire [12:0] end_offset = {1'b0,base[11:0]} + ({5'b0,len} + 13'd1) * 13'd4;
    assign arsize=3'd2;
    assign arburst=2'b01;
    assign rready=receiving && take;
    assign valid=receiving && rvalid;
    assign sample=rdata;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            {busy,done,fault,arvalid,receiving,araddr,arlen,remaining} <= '0;
        end else begin
            done <= 0;
            if (!busy && start) begin
                fault <= 0;
                if (base[1:0]!=0 || end_offset>4096) begin
                    fault <= 1;
                    done <= 1;
                end else begin
                    busy <= 1;
                    arvalid <= 1;
                    araddr <= base;
                    arlen <= len;
                    remaining <= len;
                end
            end
            if (arvalid && arready) begin
                arvalid <= 0;
                receiving <= 1;
            end
            if (rvalid && rready) begin
                if (rresp!=0 || rlast!=(remaining==0)) fault <= 1;
                if (rlast) begin busy<=0; receiving<=0; done<=1; end
                else remaining <= remaining-1'b1;
            end
        end
    end
endmodule

// Paired responder for aligned 32-bit INCR requests. Single implicit ID.
module burst_rom(
    input logic clk, rst_n,
    input logic [31:0] araddr, input logic [7:0] arlen,
    input logic arvalid, output logic arready,
    output logic [31:0] rdata, output logic [1:0] rresp,
    output logic rvalid, rlast, input logic rready
);
    logic [31:0] address;
    logic [7:0] remaining;
    assign arready=rst_n && !rvalid;
    assign rresp=0;
    assign rdata=address ^ 32'h5aa50000;
    assign rlast=rvalid && remaining==0;
    always_ff @(posedge clk) begin
        if (!rst_n) begin rvalid<=0; address<=0; remaining<=0; end
        else if (arvalid && arready) begin
            address<=araddr;
            remaining<=arlen;
            rvalid<=1;
        end else if (rvalid && rready) begin
            if (rlast) rvalid<=0;
            else begin address<=address+4; remaining<=remaining-1'b1; end
        end
    end
endmodule
