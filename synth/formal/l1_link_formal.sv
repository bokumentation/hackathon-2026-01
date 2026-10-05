module l1_link_formal (
    input wire        clk,
    input wire        rst_n,
    input wire        frame_bit,
    input wire        load_en,
    input wire        key_mode,
    input wire        done
);
    wire [63:0] key_out;
    wire        key_load;
    wire [31:0] counter_out;
    wire [63:0] payload_out;
    wire [31:0] tag_out;
    wire        start;
    wire        key_locked;

    l1_serial_loader dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .frame_bit  (frame_bit),
        .load_en    (load_en),
        .key_mode   (key_mode),
        .done       (done),
        .key_out    (key_out),
        .key_load   (key_load),
        .counter_out(counter_out),
        .payload_out(payload_out),
        .tag_out    (tag_out),
        .start      (start),
        .key_locked (key_locked)
    );

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

    // P3: key_load can only assert while key was not already locked
    // (key_locked latches on the cycle AFTER key_load, so at the moment
    //  key_load fires, key_locked_r is still 0)
    always @(posedge clk) begin
        if (rst_n)
            assert (!key_load || !key_locked);
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

endmodule
