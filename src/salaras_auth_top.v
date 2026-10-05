`default_nettype none

module salaras_auth_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] key,
    input  wire        key_load,
    input  wire [31:0] counter,
    input  wire [63:0] payload,
    input  wire [31:0] tag_in,
    input  wire        start,
    input  wire        fault_ack,
    output wire        host_full,
    output wire [95:0] host_data_q,
    output wire        fault,
    output wire        auth_ok,
    output wire        fresh_ok,
    output wire        done
);
    wire        verify_ok;
    wire        freshness_ok;
    wire        l2_done;
    wire [31:0] tag_computed;
    wire [15:0] l2_latency;

    l2_auth u_l2 (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .counter(counter),
        .payload(payload),
        .tag_in(tag_in),
        .start(start),
        .auth_ok(verify_ok),
        .fresh_ok(freshness_ok),
        .done(l2_done),
        .tag_computed(tag_computed),
        .latency(l2_latency)
    );

    l3_commit_gatekeeper u_l3 (
        .clk(clk),
        .rst_n(rst_n),
        .frame_done(l2_done),
        .framing_ok(verify_ok),
        .crc_ok(freshness_ok),
        .frame_data({counter, payload}),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(fault)
    );

    assign auth_ok  = verify_ok;
    assign fresh_ok = freshness_ok;
    assign done     = l2_done;
endmodule

`default_nettype wire
