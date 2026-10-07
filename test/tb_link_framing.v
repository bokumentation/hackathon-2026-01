`default_nettype none
`timescale 1ns / 1ps

module tb_link_framing ();

    initial begin
        $dumpfile("link_framing.vcd");
        $dumpvars(0, tb_link_framing);
    end

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg        rst_n;
    reg        serial_in;
    reg        fault_ack;

    wire [9:0] symbol;
    wire       symbol_valid;
    wire       comma;
    wire       word_lock;
    wire       timeout_fault;

    l1_link_framing dut (
        .clk(clk),
        .rst_n(rst_n),
        .serial_in(serial_in),
        .fault_ack(fault_ack),
        .symbol(symbol),
        .symbol_valid(symbol_valid),
        .comma(comma),
        .word_lock(word_lock),
        .timeout_fault(timeout_fault)
    );

endmodule

`default_nettype wire
