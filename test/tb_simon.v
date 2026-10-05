`default_nettype none
`timescale 1ns / 1ps

module tb_simon ();

    initial begin
        $dumpfile("simon.vcd");
        $dumpvars(0, tb_simon);
    end

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg         rst_n;
    reg  [63:0] key;
    reg         key_load;
    reg  [31:0] block_in;
    reg         start;

    wire [31:0] block_out;
    wire        done;
    wire [5:0]  rounds_done;

    simon32_64 dut (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .block_in(block_in),
        .start(start),
        .block_out(block_out),
        .done(done),
        .rounds_done(rounds_done)
    );

endmodule
