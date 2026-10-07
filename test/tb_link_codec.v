`default_nettype none
`timescale 1ns / 1ps

module tb_link_codec ();

    initial begin
        $dumpfile("link_codec.vcd");
        $dumpvars(0, tb_link_codec);
    end

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg        rst_n;

    reg        enc_valid;
    reg        enc_is_k;
    reg  [7:0] enc_din;
    wire [9:0] enc_dout;
    wire       enc_dout_valid;

    link_enc_8b10b u_enc (
        .clk(clk),
        .rst_n(rst_n),
        .valid(enc_valid),
        .is_k(enc_is_k),
        .din(enc_din),
        .dout(enc_dout),
        .dout_valid(enc_dout_valid)
    );

    reg        dec_valid;
    reg  [9:0] dec_din;
    wire [7:0] dec_dout;
    wire       dec_is_k;
    wire       dec_dout_valid;
    wire       dec_code_error;
    wire       dec_disp_error;

    link_dec_10b8b u_dec (
        .clk(clk),
        .rst_n(rst_n),
        .valid(dec_valid),
        .din(dec_din),
        .dout(dec_dout),
        .is_k(dec_is_k),
        .dout_valid(dec_dout_valid),
        .code_error(dec_code_error),
        .disp_error(dec_disp_error)
    );

endmodule

`default_nettype wire
