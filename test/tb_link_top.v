`default_nettype none
`timescale 1ns / 1ps

module tb_link_top ();

    initial begin
        $dumpfile("link_top.vcd");
        $dumpvars(0, tb_link_top);
    end

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg         rst_n;
    reg  [127:0] tx_frame;
    reg         tx_send;
    reg         corrupt;
    reg  [63:0] key;
    reg         key_load;
    reg         fault_ack;

    wire        tx_serial;
    wire        tx_busy;
    wire        tx_done;
    wire [95:0] host_data_q;
    wire        host_full;
    wire        fault;
    wire        auth_ok;
    wire        fresh_ok;
    wire        done;
    wire        word_lock;

    link_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .send(tx_send),
        .frame(tx_frame),
        .serial_out(tx_serial),
        .busy(tx_busy),
        .done(tx_done)
    );

    wire serial_wire = tx_serial ^ corrupt;

    link_top u_link (
        .clk(clk),
        .rst_n(rst_n),
        .serial_in(serial_wire),
        .key(key),
        .key_load(key_load),
        .fault_ack(fault_ack),
        .host_data_q(host_data_q),
        .host_full(host_full),
        .fault(fault),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done),
        .word_lock(word_lock)
    );

endmodule

`default_nettype wire
