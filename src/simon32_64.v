`default_nettype none

module simon32_64 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] key,
    input  wire        key_load,
    input  wire [31:0] block_in,
    input  wire        start,
    output reg  [31:0] block_out,
    output reg         done,
    output reg  [5:0]  rounds_done
);
    localparam [61:0] Z0 = 62'h19C3522FB386A45F;

    reg [15:0] kw0;
    reg [15:0] kw1;
    reg [15:0] kw2;
    reg [15:0] kw3;

    reg [15:0] prev1;
    reg [15:0] prev2;
    reg [15:0] prev3;
    reg [15:0] prev4;

    reg [15:0] x;
    reg [15:0] y;
    reg [5:0]  i;
    reg        busy;

    wire [15:0] x_rot1 = {x[14:0], x[15]};
    wire [15:0] x_rot8 = {x[7:0], x[15:8]};
    wire [15:0] x_rot2 = {x[13:0], x[15:14]};

    wire [15:0] fx = (x_rot1 & x_rot8) ^ x_rot2;

    wire [15:0] kp_a = {prev1[2:0], prev1[15:3]};
    wire [15:0] kp_tmp = kp_a ^ prev3;
    wire [15:0] kp_r = {kp_tmp[0], kp_tmp[15:1]};

    wire [4:0] z_idx = i[4:0] - 5'd4;
    wire [15:0] z_bit = {15'b0, Z0[z_idx]};

    reg [15:0] rkey;

    always @(*) begin
        case (i)
            6'd0:    rkey = kw0;
            6'd1:    rkey = kw1;
            6'd2:    rkey = kw2;
            6'd3:    rkey = kw3;
            default: rkey = 16'hFFFC ^ z_bit ^ prev4 ^ (kp_tmp ^ kp_r);
        endcase
    end

    wire [15:0] next_x = y ^ fx ^ rkey;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            kw0         <= 16'd0;
            kw1         <= 16'd0;
            kw2         <= 16'd0;
            kw3         <= 16'd0;
            prev1       <= 16'd0;
            prev2       <= 16'd0;
            prev3       <= 16'd0;
            prev4       <= 16'd0;
            x           <= 16'd0;
            y           <= 16'd0;
            i           <= 6'd0;
            busy        <= 1'b0;
            done        <= 1'b0;
            rounds_done <= 6'd0;
            block_out   <= 32'd0;
        end else begin
            done <= 1'b0;

            if (key_load) begin
                kw0 <= key[15:0];
                kw1 <= key[31:16];
                kw2 <= key[47:32];
                kw3 <= key[63:48];
            end

            if (start) begin
                x           <= block_in[31:16];
                y           <= block_in[15:0];
                i           <= 6'd0;
                busy        <= 1'b1;
                rounds_done <= 6'd0;
                prev1       <= 16'd0;
                prev2       <= 16'd0;
                prev3       <= 16'd0;
                prev4       <= 16'd0;
            end else if (busy) begin
                x    <= next_x;
                y    <= x;
                prev4 <= prev3;
                prev3 <= prev2;
                prev2 <= prev1;
                prev1 <= rkey;
                if (i == 6'd31) begin
                    busy        <= 1'b0;
                    done        <= 1'b1;
                    block_out   <= {next_x, x};
                    rounds_done <= 6'd32;
                    i           <= 6'd0;
                end else begin
                    i           <= i + 6'd1;
                    rounds_done <= i + 6'd1;
                end
            end
        end
    end
endmodule

`default_nettype wire
