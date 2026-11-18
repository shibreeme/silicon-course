module apb_requester(
    input logic clk, rst_n, cmd_valid, cmd_write,
    output logic cmd_ready, done, error,
    input logic [7:0] cmd_addr,
    input logic [31:0] cmd_data,
    output logic [31:0] read_data,
    output logic psel, penable, pwrite,
    output logic [7:0] paddr,
    output logic [31:0] pwdata,
    input logic pready, pslverr,
    input logic [31:0] prdata
);
    typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
    state_t state;
    assign cmd_ready = rst_n && state == IDLE;
    assign psel = state != IDLE;
    assign penable = state == ACCESS;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            {done,error,pwrite,paddr,pwdata,read_data} <= '0;
        end else begin
            done <= 0;
            case (state)
                IDLE: if (cmd_valid) begin
                    pwrite <= cmd_write;
                    paddr <= cmd_addr;
                    pwdata <= cmd_data;
                    state <= SETUP;
                end
                SETUP: state <= ACCESS;
                ACCESS: if (pready) begin
                    done <= 1;
                    error <= pslverr;
                    if (!pwrite) read_data <= prdata;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

module apb_registers(
    input logic clk, rst_n, psel, penable, pwrite,
    input logic [7:0] paddr,
    input logic [31:0] pwdata,
    output logic pready, pslverr,
    output logic [31:0] prdata
);
    // Address 0 is scratch; address 4 is a read-only write counter.
    logic [31:0] scratch, writes;
    logic waiting;
    assign pready = psel && penable && !waiting;
    assign pslverr = pready && !(paddr == 0 || (paddr == 4 && !pwrite));
    assign prdata = (paddr == 0) ? scratch : (paddr == 4) ? writes : 0;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scratch <= 0;
            writes <= 0;
            waiting <= 0;
        end else begin
            waiting <= psel && !penable;
            if (pready && pwrite && !pslverr) begin
                scratch <= pwdata;
                writes <= writes + 1;
            end
        end
    end
endmodule
