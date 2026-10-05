`default_nettype none
`timescale 1ns / 1ps

module tb_baseline_top ();

    initial begin
        $dumpfile("out/tb_baseline_top.vcd");
        $dumpvars(0, tb_baseline_top);
    end

    reg        clk;
    reg        rst_n;
    reg        digital_in;
    reg        halt;
    reg [3:0]  address;

    wire [7:0] ui_in = {address, 1'b0, halt, 1'b0, digital_in};
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    wire [7:0] parallel_out = uo_out;
    wire       full = uio_out[0];

    tt_um_dusterthefirst_project dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(8'b00000000),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(1'b1),
        .clk(clk),
        .rst_n(rst_n)
    );

endmodule
