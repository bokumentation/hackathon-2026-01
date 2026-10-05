`default_nettype none

module l2_auth (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] key,
    input  wire        key_load,
    input  wire [31:0] counter,
    input  wire [63:0] payload,
    input  wire [31:0] tag_in,
    input  wire        start,
    output reg         auth_ok,
    output reg         fresh_ok,
    output reg         done,
    output reg  [31:0] tag_computed,
    output reg  [15:0] latency
);
    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_WAIT  = 2'd2;
    localparam S_FIN   = 2'd3;

    reg [1:0]  st;
    reg [1:0]  blk;
    reg [31:0] tag_cbc;
    reg [31:0] cnt_lat;
    reg [63:0] pay_lat;
    reg [31:0] tag_lat;
    reg [31:0] last_counter;
    reg        simon_start;
    reg [15:0] lat;

    wire [31:0] simon_out;
    wire        simon_done;

    wire [31:0] block_value = (blk == 2'd0) ? cnt_lat :
                              (blk == 2'd1) ? pay_lat[31:0] : pay_lat[63:32];
    wire [31:0] simon_block_in = block_value ^ tag_cbc;

    simon32_64 u_simon (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .block_in(simon_block_in),
        .start(simon_start),
        .block_out(simon_out),
        .done(simon_done),
        .rounds_done()
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st           <= S_IDLE;
            blk          <= 2'd0;
            tag_cbc      <= 32'd0;
            cnt_lat      <= 32'd0;
            pay_lat      <= 64'd0;
            tag_lat      <= 32'd0;
            last_counter <= 32'd0;
            simon_start  <= 1'b0;
            lat          <= 16'd0;
            auth_ok      <= 1'b0;
            fresh_ok     <= 1'b0;
            done         <= 1'b0;
            tag_computed <= 32'd0;
            latency      <= 16'd0;
        end else begin
            done <= 1'b0;

            case (st)
                S_IDLE: begin
                    simon_start <= 1'b0;
                    if (start) begin
                        cnt_lat <= counter;
                        pay_lat <= payload;
                        tag_lat <= tag_in;
                        tag_cbc <= 32'd0;
                        blk     <= 2'd0;
                        lat     <= 16'd0;
                        st      <= S_START;
                    end
                end

                S_START: begin
                    simon_start <= 1'b1;
                    lat         <= lat + 16'd1;
                    st          <= S_WAIT;
                end

                S_WAIT: begin
                    simon_start <= 1'b0;
                    lat         <= lat + 16'd1;
                    if (simon_done) begin
                        tag_cbc <= simon_out;
                        if (blk == 2'd2) begin
                            st <= S_FIN;
                        end else begin
                            blk <= blk + 2'd1;
                            st  <= S_START;
                        end
                    end
                end

                S_FIN: begin
                    tag_computed <= tag_cbc;
                    auth_ok      <= (tag_cbc == tag_lat);
                    fresh_ok     <= (cnt_lat > last_counter);
                    if ((tag_cbc == tag_lat) && (cnt_lat > last_counter)) begin
                        last_counter <= cnt_lat;
                    end
                    latency <= lat;
                    done    <= 1'b1;
                    st      <= S_IDLE;
                end

                default: st <= S_IDLE;
            endcase
        end
    end
endmodule

`default_nettype wire
