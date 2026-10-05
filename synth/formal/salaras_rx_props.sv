`include "salaras_rx_defs.svh"

module l1_props (
    input wire clk,
    input wire rst_n,
    input wire framing_ok,
    input wire timing_fault,
    input wire timeout_fault
);
    always @(posedge clk) begin
        if (rst_n) begin
            assert (!framing_ok || (!timing_fault && !timeout_fault));
        end
    end
endmodule

bind l1_framing_validator l1_props u_l1_props (
    .clk(clk),
    .rst_n(rst_n),
    .framing_ok(framing_ok),
    .timing_fault(timing_fault),
    .timeout_fault(timeout_fault)
);

module l2_props (
    input wire clk,
    input wire rst_n,
    input wire frame_start,
    input wire crc_ok,
    input wire [`SRX_INTEGRITY_BITS-1:0] crc_value,
    input wire [`SRX_INTEGRITY_BITS-1:0] expected_crc
);
    always @(posedge clk) begin
        if (rst_n && frame_start) begin
            assert (crc_value == `SRX_CRC_INIT);
        end
    end
endmodule

bind l2_integrity_verify l2_props u_l2_props (
    .clk(clk),
    .rst_n(rst_n),
    .frame_start(frame_start),
    .crc_ok(crc_ok),
    .crc_value(crc_value),
    .expected_crc(expected_crc)
);

module l3_props (
    input wire clk,
    input wire rst_n,
    input wire frame_done,
    input wire framing_ok,
    input wire crc_ok,
    input wire host_full,
    input wire fault
);
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
            assert (!(frame_done && !(framing_ok && crc_ok)) || fault);
        end
    end
endmodule

bind l3_commit_gatekeeper l3_props u_l3_props (
    .clk(clk),
    .rst_n(rst_n),
    .frame_done(frame_done),
    .framing_ok(framing_ok),
    .crc_ok(crc_ok),
    .host_full(host_full),
    .fault(fault)
);
