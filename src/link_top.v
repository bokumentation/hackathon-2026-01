`default_nettype none

module link_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        serial_in,
    input  wire [63:0] key,
    input  wire        key_load,
    input  wire        fault_ack,
    output wire [95:0] host_data_q,
    output wire        host_full,
    output wire        fault,
    output wire        auth_ok,
    output wire        fresh_ok,
    output wire        done,
    output wire        word_lock
);
    wire [31:0] counter;
    wire [63:0] payload;
    wire [31:0] tag;
    wire        start;
    wire        framing_ok;
    wire        link_fault;
    wire        l3_fault;

    link_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .serial_in(serial_in),
        .done(done),
        .fault_ack(fault_ack),
        .counter(counter),
        .payload(payload),
        .tag(tag),
        .start(start),
        .framing_ok(framing_ok),
        .link_fault(link_fault),
        .word_lock(word_lock)
    );

    boundary_top u_l2l3 (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .counter(counter),
        .payload(payload),
        .tag_in(tag),
        .start(start),
        .framing_ok(framing_ok),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(l3_fault),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done)
    );

    assign fault = l3_fault | link_fault;
endmodule

`default_nettype wire
