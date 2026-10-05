`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end

  reg clk;
  reg rst_n;
  reg ena;
  reg digital_in;
  reg fault_ack;
  reg [3:0] address;

  wire [7:0] host_data;
  wire host_full;
  wire fault;
  wire manchester_clock;
  wire manchester_data;

  wire [7:0] ui_in  = {address, 2'b00, fault_ack, digital_in};
  wire [7:0] uio_in = 8'b00000000;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  tt_um_bokumentation_salaras_rx user_project (
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

  assign host_data        = uo_out;
  assign host_full        = uio_out[0];
  assign fault            = uio_out[1];
  assign manchester_clock = uio_out[2];
  assign manchester_data  = uio_out[3];

endmodule
