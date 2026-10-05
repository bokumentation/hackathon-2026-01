`default_nettype none
`timescale 1ns / 1ps

module tb_serial_baseline ();

    initial begin
        $dumpfile("out/tb_serial_baseline.vcd");
        $dumpvars(0, tb_serial_baseline);
    end

    reg        clk;
    reg        rst_n;
    reg        sclk;
    reg        sdata;

    wire        full;
    wire [31:0] thermostat_id;
    wire [15:0] room_temp;
    wire [15:0] set_temp;
    wire [7:0]  state;
    wire [7:0]  tail_1;
    wire [7:0]  tail_2;
    wire [7:0]  tail_3;

    serial_decode dut (
        .reset_n(rst_n),
        .clock(clk),
        .serial_clock(sclk),
        .serial_data(sdata),
        .full(full),
        .thermostat_id(thermostat_id),
        .room_temp(room_temp),
        .set_temp(set_temp),
        .state(state),
        .tail_1(tail_1),
        .tail_2(tail_2),
        .tail_3(tail_3)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

endmodule
