`default_nettype none

module simon32_64 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] key,
    input  wire        key_load,
    input  wire [31:0] block_in,
    input  wire        start,
    output wire [31:0] block_out,
    output wire        done,
    output wire [5:0]  rounds_done
);
    (* anyseq *) reg [31:0] abstract_block_out;
    (* anyseq *) reg        abstract_done;
    (* anyseq *) reg [5:0]  abstract_rounds_done;

    assign block_out   = abstract_block_out;
    assign done        = abstract_done;
    assign rounds_done = abstract_rounds_done;

    wire _unused = &{1'b0, clk, rst_n, key, key_load, block_in, start, 1'b0};
endmodule

`default_nettype wire
