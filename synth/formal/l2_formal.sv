`include "salaras_rx_defs.svh"

module l2_formal (
    input wire clk,
    input wire rst_n,
    input wire frame_start,
    input wire bit_valid,
    input wire bit_data,
    input wire frame_done,
    input wire [`SRX_INTEGRITY_BITS-1:0] expected_crc
);
    wire crc_ok;
    wire [`SRX_INTEGRITY_BITS-1:0] crc_value;

    l2_integrity_verify dut (
        .clk(clk),
        .rst_n(rst_n),
        .frame_start(frame_start),
        .bit_valid(bit_valid),
        .bit_data(bit_data),
        .frame_done(frame_done),
        .expected_crc(expected_crc),
        .crc_value(crc_value),
        .crc_ok(crc_ok)
    );

    reg [2:0] rst_cnt = 3'd0;

    always @(posedge clk) begin
        if (rst_cnt != 3'd4) begin
            rst_cnt <= rst_cnt + 3'd1;
            assume (!rst_n);
        end
    end

    reg started;

    always @(posedge clk) begin
        if (!rst_n) begin
            started <= 1'b0;
        end else begin
            started <= frame_start;
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            assert (!started || (crc_value == `SRX_CRC_INIT));
        end
    end
endmodule
