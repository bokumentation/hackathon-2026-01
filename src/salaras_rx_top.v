`default_nettype none
`include "salaras_rx_defs.svh"

module salaras_rx_top (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire digital_in,
    input  wire [3:0] address,
    input  wire fault_ack,
    output wire [7:0] host_data,
    output wire host_full,
    output wire fault,
    output wire manchester_clock,
    output wire manchester_data
);
    wire din_s;

    sync2 u_sync (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(digital_in),
        .sync_out(din_s)
    );

    wire man_clock;
    wire man_data;
    wire tx_begin;
    wire pos_edge;
    wire neg_edge;

    edge_detect u_edge (
        .digital_in(din_s),
        .clock(clk),
        .reset_n(rst_n),
        .pos_edge(pos_edge),
        .neg_edge(neg_edge)
    );

    state_machine u_state (
        .clock(clk),
        .enable(enable),
        .reset_n(rst_n),
        .pos_edge(pos_edge),
        .neg_edge(neg_edge),
        .manchester_clock(man_clock),
        .manchester_data(man_data),
        .transmission_begin(tx_begin)
    );

    wire framing_ok;
    wire timing_fault;
    wire timeout_fault;

    l1_framing_validator u_l1 (
        .clk(clk),
        .rst_n(rst_n),
        .pos_edge(pos_edge),
        .neg_edge(neg_edge),
        .transmission_begin(tx_begin),
        .framing_ok(framing_ok),
        .timing_fault(timing_fault),
        .timeout_fault(timeout_fault)
    );

    wire [`SRX_PAYLOAD_BITS-1:0] payload_q;
    wire [7:0] payload_index;
    wire header_ok;
    wire payload_valid;
    wire payload_bit;
    wire frame_done;

    frame_capture u_cap (
        .clk(clk),
        .rst_n(rst_n),
        .reset_capture(tx_begin),
        .serial_clock(man_clock),
        .serial_data(man_data),
        .header_ok(header_ok),
        .payload_valid(payload_valid),
        .payload_bit(payload_bit),
        .payload_index(payload_index),
        .frame_done(frame_done),
        .payload_q(payload_q)
    );

    wire crc_ok;
    wire [`SRX_INTEGRITY_BITS-1:0] crc_value;

    l2_integrity_verify u_l2 (
        .clk(clk),
        .rst_n(rst_n),
        .frame_start(tx_begin),
        .bit_valid(payload_valid & (payload_index < `SRX_PAYLOAD_DATA_BITS)),
        .bit_data(payload_bit),
        .frame_done(frame_done),
        .expected_crc(payload_q[`SRX_INTEGRITY_BITS-1:0]),
        .crc_value(crc_value),
        .crc_ok(crc_ok)
    );

    wire [`SRX_PAYLOAD_BITS-1:0] committed;

    l3_commit_gatekeeper u_l3 (
        .clk(clk),
        .rst_n(rst_n),
        .frame_done(frame_done),
        .framing_ok(framing_ok),
        .crc_ok(crc_ok),
        .frame_data(payload_q),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(committed),
        .fault(fault)
    );

    reg [7:0] mux_data;

    always @(*) begin
        case (address)
            4'd0:    mux_data = committed[95:88];
            4'd1:    mux_data = committed[87:80];
            4'd2:    mux_data = committed[79:72];
            4'd3:    mux_data = committed[71:64];
            4'd4:    mux_data = committed[63:56];
            4'd5:    mux_data = committed[55:48];
            4'd6:    mux_data = committed[47:40];
            4'd7:    mux_data = committed[39:32];
            4'd8:    mux_data = committed[31:24];
            4'd9:    mux_data = committed[23:16];
            4'd10:   mux_data = committed[15:8];
            4'd11:   mux_data = committed[7:0];
            default: mux_data = 8'h00;
        endcase
    end

    assign host_data        = mux_data;
    assign manchester_clock = man_clock;
    assign manchester_data  = man_data;

    wire _unused = &{1'b0, timing_fault, timeout_fault, header_ok, crc_value};
endmodule

`default_nettype wire
