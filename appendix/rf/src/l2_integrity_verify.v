`default_nettype none
`include "salaras_rx_defs.svh"

module l2_integrity_verify (
    input  wire clk,
    input  wire rst_n,
    input  wire frame_start,
    input  wire bit_valid,
    input  wire bit_data,
    input  wire frame_done,
    input  wire [`SRX_INTEGRITY_BITS-1:0] expected_crc,
    output wire [`SRX_INTEGRITY_BITS-1:0] crc_value,
    output wire crc_ok
);
    reg [`SRX_INTEGRITY_BITS-1:0] crc_q;
    reg [`SRX_INTEGRITY_BITS-1:0] crc_next;
    reg                           crc_ok_q;

    always @(*) begin
        crc_next = crc_q;
        if (bit_valid) begin
            crc_next = {crc_q[`SRX_INTEGRITY_BITS-2:0], 1'b0};
            if (crc_q[`SRX_INTEGRITY_BITS-1] ^ bit_data) begin
                crc_next = crc_next ^ `SRX_CRC_POLY;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_q    <= `SRX_CRC_INIT;
            crc_ok_q <= 1'b0;
        end else if (frame_start) begin
            crc_q    <= `SRX_CRC_INIT;
            crc_ok_q <= 1'b0;
        end else begin
            if (bit_valid) begin
                crc_q <= crc_next;
            end
            if (frame_done) begin
                crc_ok_q <= (crc_next == expected_crc);
            end
        end
    end

    assign crc_value = crc_q;
    assign crc_ok    = crc_ok_q;
endmodule

`default_nettype wire
