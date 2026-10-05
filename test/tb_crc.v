`default_nettype none
`timescale 1ns / 1ps

module tb_crc ();

    initial begin
        $dumpfile("crc.vcd");
        $dumpvars(0, tb_crc);
    end

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg         rst_n;
    reg         frame_start;
    reg         bit_valid;
    reg         bit_data;
    reg         frame_done;
    reg  [23:0] expected_crc;

    wire [23:0] crc_value;
    wire        crc_ok;

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

endmodule
