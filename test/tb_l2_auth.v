`default_nettype none
`timescale 1ns / 1ps

module tb_l2_auth ();

    initial begin
        $dumpfile("l2_auth.vcd");
        $dumpvars(0, tb_l2_auth);
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

    wire        auth_ok;
    wire        fresh_ok;
    wire        done;
    wire [31:0] tag_computed;
    wire [15:0] latency;

    l2_auth dut (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .counter(counter),
        .payload(payload),
        .tag_in(tag_in),
        .start(start),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done),
        .tag_computed(tag_computed),
        .latency(latency)
    );

endmodule
