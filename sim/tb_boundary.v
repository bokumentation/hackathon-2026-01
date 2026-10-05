`default_nettype none
`timescale 1ns / 1ps

module tb_boundary ();

    initial begin
        $dumpfile("out/tb_boundary.vcd");
        $dumpvars(0, tb_boundary);
    end

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg rst_n;

    reg pos_edge;
    reg neg_edge;
    reg transmission_begin;

    wire framing_ok;
    wire timing_fault;
    wire timeout_fault;

    l1_framing_validator l1 (
        .clk(clk),
        .rst_n(rst_n),
        .pos_edge(pos_edge),
        .neg_edge(neg_edge),
        .transmission_begin(transmission_begin),
        .framing_ok(framing_ok),
        .timing_fault(timing_fault),
        .timeout_fault(timeout_fault)
    );

    reg         crc_ok;
    reg         frame_done;
    reg         fault_ack;
    reg [95:0]  frame_data;

    wire        host_full;
    wire [95:0] host_data_q;
    wire        fault;

    l3_commit_gatekeeper l3 (
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

endmodule
