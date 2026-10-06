`default_nettype none

module salaras_auth_de10nano (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [3:0] SW,
    input  wire       gpio_frame_bit,
    input  wire       gpio_load_en,
    input  wire       gpio_fault_ack,
    output wire [7:0] LEDR,
    output wire       gpio_host_full,
    output wire       gpio_fault,
    output wire       gpio_done
);
    wire key_mode = SW[0];

    wire [63:0] key_out;
    wire        key_load;
    wire [31:0] counter_out;
    wire [63:0] payload_out;
    wire [31:0] tag_out;
    wire        start;
    (* preserve, noprune *) wire key_locked;

    (* preserve, noprune *) wire        host_full;
    wire [95:0] host_data_q;
    (* preserve, noprune *) wire        fault;
    (* preserve, noprune *) wire        auth_ok;
    (* preserve, noprune *) wire        fresh_ok;
    (* preserve, noprune *) wire        done;

    l1_serial_loader u_l1 (
        .clk        (CLOCK_50),
        .rst_n      (KEY[0]),
        .frame_bit  (gpio_frame_bit),
        .load_en    (gpio_load_en),
        .key_mode   (key_mode),
        .done       (done),
        .key_out    (key_out),
        .key_load   (key_load),
        .counter_out(counter_out),
        .payload_out(payload_out),
        .tag_out    (tag_out),
        .start      (start),
        .key_locked (key_locked)
    );

    salaras_auth_top u_l2l3 (
        .clk        (CLOCK_50),
        .rst_n      (KEY[0]),
        .key        (key_out),
        .key_load   (key_load),
        .counter    (counter_out),
        .payload    (payload_out),
        .tag_in     (tag_out),
        .start      (start),
        .fault_ack  (gpio_fault_ack),
        .host_full  (host_full),
        .host_data_q(host_data_q),
        .fault      (fault),
        .auth_ok    (auth_ok),
        .fresh_ok   (fresh_ok),
        .done       (done)
    );

    assign LEDR[0] = done;
    assign LEDR[1] = host_full;
    assign LEDR[2] = fault;
    assign LEDR[3] = auth_ok;
    assign LEDR[4] = fresh_ok;
    assign LEDR[5] = key_locked;
    assign LEDR[7:6] = 2'b0;

    assign gpio_host_full = host_full;
    assign gpio_fault     = fault;
    assign gpio_done      = done;

    wire _unused = &{1'b0, SW[3:1], host_data_q};
endmodule

`default_nettype wire
