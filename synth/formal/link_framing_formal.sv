module link_framing_formal (
    input wire clk,
    input wire rst_n,
    input wire serial_in,
    input wire fault_ack
);
    wire [9:0] symbol;
    wire       symbol_valid;
    wire       comma;
    wire       word_lock;
    wire       timeout_fault;

    l1_link_framing dut (
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

    reg [2:0] rst_cnt = 3'd0;

    always @(posedge clk) begin
        if (rst_cnt != 3'd4) begin
            rst_cnt <= rst_cnt + 3'd1;
            assume (!rst_n);
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            assert (!symbol_valid || word_lock);
            assert (!comma || word_lock);
            if ($past(timeout_fault) && !$past(fault_ack))
                assert (timeout_fault);
        end
    end
endmodule
