`default_nettype none

module link_tx (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         send,
    input  wire [127:0] frame,
    output reg          serial_out,
    output reg          busy,
    output reg          done
);
    localparam [1:0] S_IDLE  = 2'd0;
    localparam [1:0] S_START = 2'd1;
    localparam [1:0] S_DATA  = 2'd2;

    reg [1:0]   mode;
    reg [4:0]   byte_idx;
    reg [127:0] sh_frame;
    reg [3:0]   bit_cnt;
    reg [9:0]   code_cur;
    reg         tx_pending;

    wire [9:0]  enc_dout;

    link_enc_8b10b u_enc (
        .clk(clk),
        .rst_n(rst_n),
        .valid(enc_valid),
        .is_k(enc_is_k),
        .din(enc_din),
        .dout(enc_dout),
        .dout_valid()
    );

    reg [1:0] n_mode;
    reg [4:0] n_bidx;

    always @(*) begin
        case (mode)
            S_IDLE:  begin n_mode = tx_pending ? S_START : S_IDLE; n_bidx = 5'd0; end
            S_START: begin n_mode = S_DATA;   n_bidx = 5'd0; end
            default: begin
                if (byte_idx == 5'd15) begin n_mode = S_IDLE; n_bidx = 5'd0; end
                else begin n_mode = S_DATA; n_bidx = byte_idx + 5'd1; end
            end
        endcase
    end

    wire [7:0] n_base = 8'd127 - {n_bidx, 3'b000};
    wire [7:0] n_byte = (n_mode == S_DATA) ? sh_frame[n_base -: 8] : 8'hBC;
    wire       n_is_k = (n_mode != S_DATA);

    wire req = (bit_cnt == 4'd9) || (bit_cnt == 4'd10);

    wire       enc_valid = req;
    wire [7:0] enc_din   = n_byte;
    wire       enc_is_k  = n_is_k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode       <= S_IDLE;
            byte_idx   <= 5'd0;
            sh_frame   <= 128'd0;
            bit_cnt    <= 4'd10;
            code_cur   <= 10'd0;
            tx_pending <= 1'b0;
            serial_out <= 1'b1;
            busy       <= 1'b0;
            done       <= 1'b0;
        end else begin
            done <= 1'b0;
            busy <= (mode != S_IDLE);

            if (send && mode == S_IDLE) begin
                tx_pending <= 1'b1;
                sh_frame   <= frame;
            end

            case (bit_cnt)
                4'd10: begin
                    bit_cnt <= 4'd0;
                end
                4'd0: begin
                    serial_out <= enc_dout[0];
                    code_cur   <= {1'b0, enc_dout[9:1]};
                    bit_cnt    <= 4'd1;
                end
                4'd9: begin
                    serial_out <= code_cur[0];
                    if (mode == S_DATA && byte_idx == 5'd15) begin
                        done <= 1'b1;
                    end
                    if (mode == S_IDLE && tx_pending) tx_pending <= 1'b0;
                    mode     <= n_mode;
                    byte_idx <= n_bidx;
                    bit_cnt  <= 4'd0;
                end
                default: begin
                    serial_out <= code_cur[0];
                    code_cur   <= {1'b0, code_cur[9:1]};
                    bit_cnt    <= bit_cnt + 4'd1;
                end
            endcase
        end
    end
endmodule

`default_nettype wire
