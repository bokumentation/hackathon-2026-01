module auth_data_integrity (
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
        .framing_ok(1'b1),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(fault),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done)
    );

    reg [31:0] cfg_counter;
    reg [63:0] cfg_payload;
    reg        frame_pending;
    reg [31:0] committed_counter;
    reg [63:0] committed_payload;

    always @(posedge clk) begin
        if (!rst_n) begin
            cfg_counter       <= 32'd0;
            cfg_payload       <= 64'd0;
            frame_pending     <= 1'b0;
            committed_counter <= 32'd0;
            committed_payload <= 64'd0;
        end else begin
            if (start && !frame_pending) begin
                cfg_counter   <= counter;
                cfg_payload   <= payload;
                frame_pending <= 1'b1;
            end
            if (done) begin
                committed_counter <= cfg_counter;
                committed_payload <= cfg_payload;
                frame_pending     <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            assume (!start || !frame_pending);
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
            if (host_full) begin
                assert (host_data_q == {committed_counter, committed_payload});
            end
        end
    end
endmodule
