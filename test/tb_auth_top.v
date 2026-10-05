`default_nettype none
`timescale 1ns / 1ps

module tb_auth_top ();

    initial begin
        $dumpfile("auth_top.vcd");
        $dumpvars(0, tb_auth_top);
    end

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg         rst_n;

    reg  [63:0] key;
    reg         key_load;
    reg  [31:0] counter;
    reg  [63:0] payload;
    reg  [31:0] tag_in;
    reg         start;
    reg         fault_ack;

    wire        host_full;
    wire [95:0] host_data_q;
    wire        fault;
    wire        auth_ok;
    wire        fresh_ok;
    wire        done;

    salaras_auth_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .counter(counter),
        .payload(payload),
        .tag_in(tag_in),
        .start(start),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(fault),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done)
    );

    reg         p_frame_done;
    reg         p_framing_ok;
    reg         p_crc_ok;
    reg  [95:0] p_frame_data;
    reg         p_fault_ack;

    wire        p_host_full;
    wire [95:0] p_host_data_q;
    wire        p_fault;

    l3_commit_gatekeeper u_profile (
        .clk(clk),
        .rst_n(rst_n),
        .frame_done(p_frame_done),
        .framing_ok(p_framing_ok),
        .crc_ok(p_crc_ok),
        .frame_data(p_frame_data),
        .fault_ack(p_fault_ack),
        .host_full(p_host_full),
        .host_data_q(p_host_data_q),
        .fault(p_fault)
    );

endmodule
