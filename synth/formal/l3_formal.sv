`include "salaras_rx_defs.svh"

module l3_formal (
    input wire clk,
    input wire rst_n,
    input wire frame_done,
    input wire framing_ok,
    input wire crc_ok,
    input wire fault_ack,
    input wire [`SRX_PAYLOAD_BITS-1:0] frame_data
);
    wire host_full;
    wire [`SRX_PAYLOAD_BITS-1:0] host_data_q;
    wire fault;

    l3_commit_gatekeeper dut (
        .clk(clk),
        .rst_n(rst_n),
        .frame_done(frame_done),
        .framing_ok(framing_ok),
        .crc_ok(crc_ok),
        .frame_data(frame_data),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(fault)
    );

    reg [2:0] rst_cnt = 3'd0;

    always @(posedge clk) begin
        if (rst_cnt != 3'd4) begin
            rst_cnt <= rst_cnt + 3'd1;
            assume (!rst_n);
        end
    end

    reg accepted;

    always @(posedge clk) begin
        if (!rst_n) begin
            accepted <= 1'b0;
        end else if (frame_done) begin
            accepted <= framing_ok & crc_ok;
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            assert (!host_full || accepted);
        end
    end
endmodule
