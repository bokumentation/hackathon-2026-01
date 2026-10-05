`default_nettype none

module salaras_auth_de10nano (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    input  wire       gpio_frame_bit,
    input  wire       gpio_load_en,
    input  wire       gpio_fault_ack,
    output wire [9:0] LEDR,
    output wire       gpio_host_full,
    output wire       gpio_fault,
    output wire       gpio_done
);
    localparam S_LOAD  = 2'd0;
    localparam S_KEY   = 2'd1;
    localparam S_START = 2'd2;
    localparam S_WAIT  = 2'd3;

    reg [1:0]   st;
    reg [191:0] sr;
    reg [7:0]   bit_count;
    reg         key_load_q;
    reg         start_q;

    wire [63:0] key     = sr[191:128];
    wire [31:0] counter = sr[127:96];
    wire [63:0] payload = sr[95:32];
    wire [31:0] tag_in  = sr[31:0];

    wire        host_full;
    wire [95:0] host_data_q;
    wire        fault;
    wire        auth_ok;
    wire        fresh_ok;
    wire        done;

    salaras_auth_top core (
        .clk(CLOCK_50),
        .rst_n(KEY[0]),
        .key(key),
        .key_load(key_load_q),
        .counter(counter),
        .payload(payload),
        .tag_in(tag_in),
        .start(start_q),
        .fault_ack(gpio_fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(fault),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done)
    );

    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if (!KEY[0]) begin
            st         <= S_LOAD;
            sr         <= 192'd0;
            bit_count  <= 8'd0;
            key_load_q <= 1'b0;
            start_q    <= 1'b0;
        end else begin
            key_load_q <= 1'b0;
            start_q    <= 1'b0;

            case (st)
                S_LOAD: begin
                    if (gpio_load_en) begin
                        sr        <= {sr[190:0], gpio_frame_bit};
                        bit_count <= bit_count + 8'd1;
                        if (bit_count == 8'd191) begin
                            st <= S_KEY;
                        end
                    end else begin
                        bit_count <= 8'd0;
                    end
                end
                S_KEY: begin
                    key_load_q <= 1'b1;
                    st         <= S_START;
                end
                S_START: begin
                    start_q <= 1'b1;
                    st      <= S_WAIT;
                end
                S_WAIT: begin
                    if (done) begin
                        st <= S_LOAD;
                    end
                end
                default: st <= S_LOAD;
            endcase
        end
    end

    assign LEDR[0] = done;
    assign LEDR[1] = host_full;
    assign LEDR[2] = fault;
    assign LEDR[3] = auth_ok;
    assign LEDR[4] = fresh_ok;
    assign LEDR[9:5] = 5'b0;

    assign gpio_host_full = host_full;
    assign gpio_fault     = fault;
    assign gpio_done      = done;

    wire _unused = &{1'b0, SW, host_data_q};
endmodule

`default_nettype wire
