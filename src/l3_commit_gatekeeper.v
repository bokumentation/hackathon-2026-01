`default_nettype none
`include "salaras_rx_defs.svh"

module l3_commit_gatekeeper (
    input  wire clk,
    input  wire rst_n,
    input  wire frame_done,
    input  wire framing_ok,
    input  wire crc_ok,
    input  wire [`SRX_PAYLOAD_BITS-1:0] frame_data,
    input  wire fault_ack,
    output wire host_full,
    output wire [`SRX_PAYLOAD_BITS-1:0] host_data_q,
    output wire fault
);
    wire accept = framing_ok & crc_ok;

    reg host_full_q;
    reg [`SRX_PAYLOAD_BITS-1:0] host_data_d;
    reg fault_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            host_full_q <= 1'b0;
            host_data_d <= {`SRX_PAYLOAD_BITS{1'b0}};
            fault_q     <= 1'b0;
        end else begin
            if (fault_ack) begin
                fault_q <= 1'b0;
            end
            if (frame_done) begin
                if (accept) begin
                    host_data_d <= frame_data;
                    host_full_q <= 1'b1;
                end else begin
                    host_full_q <= 1'b0;
                    fault_q     <= 1'b1;
                end
            end
        end
    end

    assign host_full   = host_full_q;
    assign host_data_q = host_data_d;
    assign fault       = fault_q;
endmodule

`default_nettype wire
