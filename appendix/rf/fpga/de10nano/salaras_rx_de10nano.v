`default_nettype none

module salaras_rx_de10nano (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    input  wire       digital_in,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1
);
    localparam integer HALF_DIV = 1250;

    reg [15:0] div_cnt;
    reg        clk_20k;

    always @(posedge CLOCK_50) begin
        if (div_cnt == HALF_DIV - 1) begin
            div_cnt <= 16'd0;
            clk_20k <= ~clk_20k;
        end else begin
            div_cnt <= div_cnt + 16'd1;
        end
    end

    wire [7:0] host_data;
    wire host_full;
    wire fault;
    wire man_clock;
    wire man_data;

    salaras_rx_top core (
        .clk(clk_20k),
        .rst_n(KEY[0]),
        .enable(1'b1),
        .digital_in(digital_in),
        .address(SW[3:0]),
        .fault_ack(SW[4]),
        .host_data(host_data),
        .host_full(host_full),
        .fault(fault),
        .manchester_clock(man_clock),
        .manchester_data(man_data)
    );

    assign LEDR[7:0] = host_data;
    assign LEDR[8]   = host_full;
    assign LEDR[9]   = fault;

    assign HEX0 = 7'b1111111;
    assign HEX1 = {4'b1111, man_clock, man_data, 1'b1};

    wire _unused = &{1'b0, KEY[1], SW[9:5]};
endmodule

`default_nettype wire
