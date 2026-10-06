`default_nettype none

module link_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        serial_in,
    input  wire        done,
    input  wire        fault_ack,
    output reg  [31:0] counter,
    output reg  [63:0] payload,
    output reg  [31:0] tag,
    output reg         start,
    output reg         framing_ok,
    output wire        link_fault,
    output wire        word_lock
);
    wire [9:0] symbol;
    wire       symbol_valid;
    wire       comma;
    wire       timeout_fault;

    l1_link_framing u_fr (
        .clk(clk),
        .rst_n(rst_n),
        .serial_in(serial_in),
        .fault_ack(fault_ack),
        .symbol(symbol),
        .symbol_valid(symbol_valid),
        .comma(comma),
        .word_lock(word_lock),
        .timeout_fault(timeout_fault)
    );

    wire [7:0] dec_dout;
    wire       dec_is_k;
    wire       dec_code_error;
    wire       dec_disp_error;
    wire       dec_dout_valid;

    link_dec_10b8b u_dec (
        .clk(clk),
        .rst_n(rst_n),
        .valid(symbol_valid),
        .din(symbol),
        .dout(dec_dout),
        .is_k(dec_is_k),
        .dout_valid(dec_dout_valid),
        .code_error(dec_code_error),
        .disp_error(dec_disp_error)
    );

    reg        sv_d;
    reg        comma_d;
    reg [4:0]  byte_cnt;
    reg [127:0] frame_sr;
    reg        busy;
    reg        err_fault;

    wire [127:0] full_frame = {frame_sr[119:0], dec_dout};

    wire _unused = &{1'b0, dec_is_k, dec_dout_valid, frame_sr[127:120]};

    assign link_fault = err_fault | timeout_fault;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sv_d       <= 1'b0;
            comma_d    <= 1'b0;
            byte_cnt   <= 5'd0;
            frame_sr   <= 128'd0;
            busy       <= 1'b0;
            err_fault  <= 1'b0;
            counter    <= 32'd0;
            payload    <= 64'd0;
            tag        <= 32'd0;
            start      <= 1'b0;
            framing_ok <= 1'b0;
        end else begin
            sv_d    <= symbol_valid;
            comma_d <= symbol_valid & comma;
            start   <= 1'b0;

            if (fault_ack) err_fault <= 1'b0;
            if (dec_code_error || dec_disp_error) begin
                err_fault  <= 1'b1;
                framing_ok <= 1'b0;
            end
            if (busy && done) busy <= 1'b0;

            if (sv_d) begin
                if (comma_d) begin
                    byte_cnt <= 5'd0;
                end else if (word_lock && !busy) begin
                    if (byte_cnt == 5'd15) begin
                        counter    <= full_frame[127:96];
                        payload    <= full_frame[95:32];
                        tag        <= full_frame[31:0];
                        start      <= 1'b1;
                        framing_ok <= 1'b1;
                        busy       <= 1'b1;
                        byte_cnt   <= 5'd0;
                    end else begin
                        frame_sr <= {frame_sr[119:0], dec_dout};
                        byte_cnt <= byte_cnt + 5'd1;
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire
