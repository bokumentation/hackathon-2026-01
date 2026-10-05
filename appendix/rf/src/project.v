`default_nettype none

module tt_um_bokumentation_salaras_rx (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire [7:0] host_data;
    wire host_full;
    wire fault;
    wire man_clock;
    wire man_data;

    salaras_rx_top core (
        .clk(clk),
        .rst_n(rst_n),
        .enable(ena),
        .digital_in(ui_in[0]),
        .address(ui_in[7:4]),
        .fault_ack(ui_in[1]),
        .host_data(host_data),
        .host_full(host_full),
        .fault(fault),
        .manchester_clock(man_clock),
        .manchester_data(man_data)
    );

    assign uo_out  = host_data;
    assign uio_out = {4'b0000, man_data, man_clock, fault, host_full};
    assign uio_oe  = 8'hFF;

    wire _unused = &{1'b0, uio_in, ui_in[3:2], ena};
endmodule

`default_nettype wire
