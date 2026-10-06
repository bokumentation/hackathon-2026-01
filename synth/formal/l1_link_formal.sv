module l1_link_formal (
    input wire        clk,
    input wire        rst_n,
    input wire        frame_bit,
    input wire        load_en,
    input wire        key_mode,
    input wire        done,
    input wire        fault_ack
);
    wire [63:0] key_out;
    wire        key_load;
    wire [31:0] counter_out;
    wire [63:0] payload_out;
    wire [31:0] tag_out;
    wire        start;
    wire        key_locked;
    wire        framing_ok;
    wire        framing_fault;
    wire        timeout_fault;

    l1_serial_loader dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .frame_bit    (frame_bit),
        .load_en      (load_en),
        .key_mode     (key_mode),
        .done         (done),
        .fault_ack    (fault_ack),
        .key_out      (key_out),
        .key_load     (key_load),
        .counter_out  (counter_out),
        .payload_out  (payload_out),
        .tag_out      (tag_out),
        .start        (start),
        .key_locked   (key_locked),
        .framing_ok   (framing_ok),
        .framing_fault(framing_fault),
        .timeout_fault(timeout_fault)
    );

    reg [2:0] rst_cnt = 3'd0;

    always @(posedge clk) begin
        if (rst_cnt != 3'd4) begin
            rst_cnt <= rst_cnt + 3'd1;
            assume (!rst_n);
        end
    end

    // P1: key_load and start are mutually exclusive (never assert together)
    always @(posedge clk) begin
        if (rst_n)
            assert (!(key_load && start));
    end

    // P2: start can only assert after key_locked is set
    always @(posedge clk) begin
        if (rst_n)
            assert (!start || key_locked);
    end

    // P3: key_load can only assert if the key was not already locked
    always @(posedge clk) begin
        if (rst_n)
            assert (!key_load || !$past(key_locked));
    end

    // P4: once key_locked is set it stays set (no second key load)
    always @(posedge clk) begin
        if (rst_n && $past(key_locked))
            assert (key_locked);
    end

    // P5: key_load is a single-cycle pulse (never two consecutive cycles)
    always @(posedge clk) begin
        if (rst_n && $past(key_load))
            assert (!key_load);
    end

    // P6: start is a single-cycle pulse
    always @(posedge clk) begin
        if (rst_n && $past(start))
            assert (!start);
    end

    // P7: a framing fault is sticky until fault_ack
    always @(posedge clk) begin
        if (rst_n && $past(framing_fault) && !$past(fault_ack))
            assert (framing_fault);
    end

    // P8: framing_ok and framing_fault are mutually exclusive
    always @(posedge clk) begin
        if (rst_n)
            assert (!(framing_ok && framing_fault));
    end
endmodule
