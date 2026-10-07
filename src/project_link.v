`default_nettype none

module tt_um_link (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire serial_in = ui_in[0];
    wire key_bit   = ui_in[1];
    wire load_en   = ui_in[2];
    wire fault_ack = ui_in[3];
    wire key_mode  = ui_in[4];

    wire [63:0] key_out;
    wire        key_load;
    wire        key_locked;
    wire [31:0] l1_counter;
    wire [63:0] l1_payload;
    wire [31:0] l1_tag;
    wire        l1_start;
    wire        l1_framing_ok;
    wire        l1_framing_fault;
    wire        l1_timeout_fault;

    wire [95:0] host_data_q;
    wire        host_full;
    wire        link_fault;
    wire        auth_ok;
    wire        fresh_ok;
    wire        link_done;
    wire        word_lock;

    l1_serial_loader u_key (
        .clk          (clk),
        .rst_n        (rst_n),
        .frame_bit    (key_bit),
        .load_en      (load_en),
        .key_mode     (key_mode),
        .done         (link_done),
        .fault_ack    (fault_ack),
        .key_out      (key_out),
        .key_load     (key_load),
        .counter_out  (l1_counter),
        .payload_out  (l1_payload),
        .tag_out      (l1_tag),
        .start        (l1_start),
        .key_locked   (key_locked),
        .framing_ok   (l1_framing_ok),
        .framing_fault(l1_framing_fault),
        .timeout_fault(l1_timeout_fault)
    );

    link_top u_link (
        .clk        (clk),
        .rst_n      (rst_n),
        .serial_in  (serial_in),
        .key        (key_out),
        .key_load   (key_load),
        .fault_ack  (fault_ack),
        .host_data_q(host_data_q),
        .host_full  (host_full),
        .fault      (link_fault),
        .auth_ok    (auth_ok),
        .fresh_ok   (fresh_ok),
        .done       (link_done),
        .word_lock  (word_lock)
    );

    wire fault = link_fault | l1_framing_fault | l1_timeout_fault;

    assign uo_out  = {link_done, host_full, fault, auth_ok, fresh_ok, word_lock, key_locked, 1'b0};
    assign uio_out = {6'b000000, fault, host_full};
    assign uio_oe  = 8'b00000011;

    wire _unused = &{1'b0, uio_in, ui_in[7:5], ena, host_data_q,
                     l1_counter, l1_payload, l1_tag, l1_start, l1_framing_ok};
endmodule

`default_nettype wire
