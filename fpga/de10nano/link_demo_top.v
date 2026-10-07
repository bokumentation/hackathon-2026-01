`default_nettype none

module link_demo_top (
    input  wire        CLOCK_50,
    input  wire [1:0]  KEY,
    input  wire [3:0]  SW,
    output wire [7:0]  LEDR
);
    localparam [63:0] DEMO_KEY = 64'h1918111009080100;
    localparam [127:0] FRAME0 = 128'h0000000111223344556677880ADFD524;
    localparam [127:0] FRAME1 = 128'h00000002AABBCCDDEEFF0011DB4AE13F;
    localparam [127:0] FRAME2 = 128'h00000003010203040506070827D3C2A9;
    localparam [127:0] FRAME3 = 128'h00000004DEADBEEFCAFEBABE199992CD;

    wire rst_n = KEY[0];
    wire [1:0] mode = SW[1:0];
    wire fault_ack = SW[2];

    function [127:0] frame_at;
        input [1:0] i;
        begin
            case (i)
                2'd0: frame_at = FRAME0;
                2'd1: frame_at = FRAME1;
                2'd2: frame_at = FRAME2;
                default: frame_at = FRAME3;
            endcase
        end
    endfunction

    reg [1:0]  init_cnt;
    reg        key_load;
    (* preserve, noprune *) wire key_load_o;

    reg [1:0]  btn_sync;
    (* preserve, noprune *) reg  send_pulse;

    reg [1:0]  idx;
    reg [127:0] last_clean;
    reg [127:0] tx_frame;
    reg         tx_send;

    (* preserve, noprune *) wire tx_busy;
    (* preserve, noprune *) wire tx_serial;
    wire tx_done;

    (* preserve, noprune *) wire host_full;
    (* preserve, noprune *) wire fault;
    (* preserve, noprune *) wire auth_ok;
    (* preserve, noprune *) wire fresh_ok;
    (* preserve, noprune *) wire done;
    (* preserve, noprune *) wire word_lock;
    wire [95:0] host_data_q;

    wire [127:0] sel = frame_at(idx);
    wire [127:0] next_frame = (mode == 2'd1) ? (sel ^ 128'h1) :
                              (mode == 2'd2) ? last_clean : sel;

    wire btn_pressed = ~KEY[1];
    wire btn_edge = btn_sync[1] & ~btn_sync[0];

    assign key_load_o = key_load;

    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            init_cnt  <= 2'd0;
            key_load  <= 1'b0;
            btn_sync  <= 2'b00;
            send_pulse<= 1'b0;
            idx       <= 2'd0;
            last_clean<= FRAME0;
            tx_frame  <= 128'd0;
            tx_send   <= 1'b0;
        end else begin
            btn_sync <= {btn_sync[0], btn_pressed};

            key_load <= (init_cnt == 2'd1);
            if (init_cnt != 2'd3) init_cnt <= init_cnt + 2'd1;

            send_pulse <= 1'b0;
            tx_send    <= 1'b0;

            if (btn_edge && !tx_busy) begin
                tx_frame   <= next_frame;
                tx_send    <= 1'b1;
                send_pulse <= 1'b1;
                if (mode == 2'd0) begin
                    last_clean <= sel;
                    idx        <= idx + 2'd1;
                end
            end
        end
    end

    link_tx u_tx (
        .clk       (CLOCK_50),
        .rst_n     (rst_n),
        .send      (tx_send),
        .frame     (tx_frame),
        .serial_out(tx_serial),
        .busy      (tx_busy),
        .done      (tx_done)
    );

    link_top u_link (
        .clk        (CLOCK_50),
        .rst_n      (rst_n),
        .serial_in  (tx_serial),
        .key        (DEMO_KEY),
        .key_load   (key_load),
        .fault_ack  (fault_ack),
        .host_data_q(host_data_q),
        .host_full  (host_full),
        .fault      (fault),
        .auth_ok    (auth_ok),
        .fresh_ok   (fresh_ok),
        .done       (done),
        .word_lock  (word_lock)
    );

    assign LEDR[0] = done;
    assign LEDR[1] = host_full;
    assign LEDR[2] = fault;
    assign LEDR[3] = auth_ok;
    assign LEDR[4] = fresh_ok;
    assign LEDR[5] = word_lock;
    assign LEDR[6] = tx_busy;
    assign LEDR[7] = (mode == 2'd0);

    wire _unused = &{1'b0, tx_done, key_load_o, send_pulse, host_data_q, SW[3]};
endmodule

`default_nettype wire
