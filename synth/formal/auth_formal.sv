module auth_formal (
    input wire        clk,
    input wire        rst_n,
    input wire        key_load,
    input wire        start,
    input wire        fault_ack,
    input wire [63:0] key,
    input wire [31:0] counter,
    input wire [63:0] payload,
    input wire [31:0] tag_in
);
    wire        host_full;
    wire [95:0] host_data_q;
    wire        fault;
    wire        auth_ok;
    wire        fresh_ok;
    wire        done;

    boundary_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load),
        .counter(counter),
        .payload(payload),
        .tag_in(tag_in),
        .start(start),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(fault),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done)
    );

    reg accepted;

    always @(posedge clk) begin
        if (!rst_n) begin
            accepted <= 1'b0;
        end else if (done) begin
            accepted <= auth_ok & fresh_ok;
        end
    end

    reg [2:0] rst_cnt = 3'd0;

    always @(posedge clk) begin
        if (rst_cnt != 3'd4) begin
            rst_cnt <= rst_cnt + 3'd1;
            assume (!rst_n);
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            assert (!host_full || accepted);
        end
    end
endmodule
