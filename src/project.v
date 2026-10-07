`default_nettype none

module tt_um_auth_boundary (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire frame_bit = ui_in[0];
    wire load_en   = ui_in[1];
    wire fault_ack = ui_in[2];
    wire key_mode  = ui_in[3];

    wire [63:0] key_out;
    wire        key_load;
    wire [31:0] counter_out;
    wire [63:0] payload_out;
    wire [31:0] tag_out;
    wire        start;
    wire        key_locked;
    wire        framing_ok;
    wire        framing_fault;
    wire        timeout_fault;

    wire        host_full;
    wire [95:0] host_data_q;
    wire        l3_fault;
    wire        auth_ok;
    wire        fresh_ok;
    wire        done;

    wire fault = l3_fault | framing_fault | timeout_fault;

    l1_serial_loader u_l1 (
        .clk          (clk),
        .rst_n        (rst_n),
        .frame_bit    (frame_bit),
        .load_en      (load_en),
        .key_mode     (key_mode),
        .done         (done),
        .fault_ack    (fault_ack),
        .key_out      (key_out),
        .key_load     (key_load),
        .counter_out  (counter_out),
        .payload_out  (payload_out),
        .tag_out      (tag_out),
        .start        (start),
        .key_locked   (key_locked),
        .framing_ok   (framing_ok),
        .framing_fault(framing_fault),
        .timeout_fault(timeout_fault)
    );

    boundary_top u_l2l3 (
        .clk        (clk),
        .rst_n      (rst_n),
        .key        (key_out),
        .key_load   (key_load),
        .counter    (counter_out),
        .payload    (payload_out),
        .tag_in     (tag_out),
        .start      (start),
        .framing_ok (framing_ok),
        .fault_ack  (fault_ack),
        .host_full  (host_full),
        .host_data_q(host_data_q),
        .fault      (l3_fault),
        .auth_ok    (auth_ok),
        .fresh_ok   (fresh_ok),
        .done       (done)
    );

    assign uo_out  = {done, host_full, fault, auth_ok, fresh_ok, key_locked, 2'b00};
    assign uio_out = {6'b000000, fault, host_full};
    assign uio_oe  = 8'b00000011;

    wire _unused = &{1'b0, uio_in, ui_in[7:4], ena, host_data_q};
endmodule

`default_nettype wire
