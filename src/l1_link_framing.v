`default_nettype none

module l1_link_framing (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       serial_in,
    input  wire       fault_ack,
    output reg  [9:0] symbol,
    output reg        symbol_valid,
    output reg        comma,
    output reg        word_lock,
    output reg        timeout_fault
);
    localparam [9:0] COMMA_RDN = 10'b0011111010;
    localparam [9:0] COMMA_RDP = 10'b1100000101;
    localparam [7:0] TIMEOUT_SYMBOLS = 8'd128;

    reg [9:0] sr;
    reg [3:0] bit_cnt;
    reg [7:0] since_comma;

    wire [9:0] sr_next = {serial_in, sr[9:1]};
    wire comma_match = (sr_next == COMMA_RDN) || (sr_next == COMMA_RDP);

    wire _unused = &{1'b0, sr[0]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sr            <= 10'd0;
            bit_cnt       <= 4'd0;
            since_comma   <= 8'd0;
            symbol        <= 10'd0;
            symbol_valid  <= 1'b0;
            comma         <= 1'b0;
            word_lock     <= 1'b0;
            timeout_fault <= 1'b0;
        end else begin
            sr           <= sr_next;
            symbol_valid <= 1'b0;
            comma        <= 1'b0;

            if (fault_ack) timeout_fault <= 1'b0;

            if (!word_lock) begin
                bit_cnt     <= 4'd0;
                since_comma <= 8'd0;
                if (comma_match) begin
                    word_lock    <= 1'b1;
                    symbol       <= sr_next;
                    symbol_valid <= 1'b1;
                    comma        <= 1'b1;
                end
            end else if (bit_cnt == 4'd9) begin
                bit_cnt      <= 4'd0;
                symbol       <= sr_next;
                symbol_valid <= 1'b1;
                comma        <= comma_match;
                if (comma_match) begin
                    since_comma <= 8'd0;
                end else if (since_comma >= TIMEOUT_SYMBOLS) begin
                    timeout_fault <= 1'b1;
                    word_lock     <= 1'b0;
                end else begin
                    since_comma <= since_comma + 8'd1;
                end
            end else begin
                bit_cnt <= bit_cnt + 4'd1;
            end
        end
    end
endmodule

`default_nettype wire
