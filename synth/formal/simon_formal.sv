module simon_formal (
    input wire        clk,
    input wire        rst_n,
    input wire        key_load,
    input wire        start,
    input wire [63:0] key,
    input wire [31:0] block_in
);
    wire [31:0] block_out;
    wire        done;
    wire [5:0]  rounds_done;

    simon32_64 dut (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .block_in(block_in),
        .start(start),
        .block_out(block_out),
        .done(done),
        .rounds_done(rounds_done)
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
            assert (!done || (rounds_done == 6'd32));
        end
    end
endmodule
