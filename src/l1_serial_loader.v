`default_nettype none

// L1 serial loader: shifts a 64-bit key and a 128-bit frame (counter + payload
// + tag) in over a single-bit interface.  Two modes are selected by key_mode:
//
//   key_mode=1, key not yet locked: shift 64 bits into key_sr MSB-first.
//     After 64 bits, key_load pulses for one cycle and key_locked latches high.
//     A second key_mode=1 session is ignored while key_locked is set.
//
//   key_mode=0, key locked: shift 128 bits into frame_sr MSB-first.
//     After 128 bits, start pulses for one cycle.
//
// Bits are captured on posedge clk when load_en is high.
// Dropping load_en resets the bit counter for the current session without
// affecting key_locked or key_sr.
//
// done is an input from the downstream auth core; the loader waits in S_WAIT
// until done goes high before accepting the next frame.  A stalled session or
// a stalled auth core raises a sticky framing or timeout fault.

module l1_serial_loader (
    input  wire        clk,
    input  wire        rst_n,

    // serial interface
    input  wire        frame_bit,  // data bit (MSB first)
    input  wire        load_en,    // capture strobe (one cycle per bit)
    input  wire        key_mode,   // 1 = key-load session, 0 = frame session

    // auth core feedback
    input  wire        done,       // auth core finished processing

    // fault control
    input  wire        fault_ack,  // clears the sticky fault flags

    // outputs to auth core
    output wire [63:0] key_out,    // latched key (stable after key_load)
    output wire        key_load,   // one-cycle pulse: load key_out into core
    output wire [31:0] counter_out,
    output wire [63:0] payload_out,
    output wire [31:0] tag_out,
    output wire        start,      // one-cycle pulse: begin MAC computation

    // status
    output wire        key_locked,  // high once key has been loaded
    output wire        framing_ok,  // high after a clean frame session
    output wire        framing_fault,
    output wire        timeout_fault
);
    localparam S_LOAD  = 2'd0;
    localparam S_KEY   = 2'd1;
    localparam S_START = 2'd2;
    localparam S_WAIT  = 2'd3;

    localparam [15:0] TIMEOUT_CYCLES = 16'd4096;

    reg [1:0]   st;
    reg [127:0] sr;
    reg [6:0]   bit_count;
    reg         key_load_q;
    reg         start_q;

    reg [63:0]  key_sr;
    reg [6:0]   key_bit_count;
    reg         key_locked_r;

    reg         framing_ok_q;
    reg         framing_fault_q;
    reg         timeout_fault_q;
    reg [15:0]  wait_timer;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st              <= S_LOAD;
            sr              <= 128'd0;
            bit_count       <= 7'd0;
            key_load_q      <= 1'b0;
            start_q         <= 1'b0;
            key_sr          <= 64'd0;
            key_bit_count   <= 7'd0;
            key_locked_r    <= 1'b0;
            framing_ok_q    <= 1'b0;
            framing_fault_q <= 1'b0;
            timeout_fault_q <= 1'b0;
            wait_timer      <= 16'd0;
        end else begin
            key_load_q <= 1'b0;
            start_q    <= 1'b0;

            if (fault_ack) begin
                framing_fault_q <= 1'b0;
                timeout_fault_q <= 1'b0;
            end

            case (st)
                S_LOAD: begin
                    if (key_mode && !key_locked_r) begin
                        if (load_en) begin
                            key_sr        <= {key_sr[62:0], frame_bit};
                            key_bit_count <= key_bit_count + 7'd1;
                            if (key_bit_count == 7'd63) begin
                                st            <= S_KEY;
                                key_bit_count <= 7'd0;
                            end
                        end else begin
                            if (key_bit_count != 7'd0) begin
                                framing_fault_q <= 1'b1;
                                framing_ok_q    <= 1'b0;
                            end
                            key_bit_count <= 7'd0;
                        end
                        bit_count <= 7'd0;
                    end else if (!key_mode && key_locked_r) begin
                        if (load_en) begin
                            if (bit_count == 7'd0) framing_ok_q <= 1'b0;
                            sr        <= {sr[126:0], frame_bit};
                            bit_count <= bit_count + 7'd1;
                            if (bit_count == 7'd127) begin
                                st        <= S_START;
                                bit_count <= 7'd0;
                            end
                        end else begin
                            if (bit_count != 7'd0) begin
                                framing_fault_q <= 1'b1;
                                framing_ok_q    <= 1'b0;
                            end
                            bit_count <= 7'd0;
                        end
                    end else begin
                        bit_count     <= 7'd0;
                        key_bit_count <= 7'd0;
                    end
                end

                S_KEY: begin
                    key_load_q   <= 1'b1;
                    key_locked_r <= 1'b1;
                    st           <= S_LOAD;
                end

                S_START: begin
                    start_q      <= 1'b1;
                    wait_timer   <= 16'd0;
                    framing_ok_q <= 1'b1;
                    st           <= S_WAIT;
                end

                S_WAIT: begin
                    if (done) begin
                        st <= S_LOAD;
                    end else begin
                        wait_timer <= wait_timer + 16'd1;
                        if (wait_timer >= TIMEOUT_CYCLES) begin
                            timeout_fault_q <= 1'b1;
                            framing_ok_q    <= 1'b0;
                            st              <= S_LOAD;
                        end
                    end
                end

                default: st <= S_LOAD;
            endcase
        end
    end

    assign key_out       = key_sr;
    assign key_load      = key_load_q;
    assign counter_out   = sr[127:96];
    assign payload_out   = sr[95:32];
    assign tag_out       = sr[31:0];
    assign start         = start_q;
    assign key_locked    = key_locked_r;
    assign framing_ok    = framing_ok_q;
    assign framing_fault = framing_fault_q;
    assign timeout_fault = timeout_fault_q;

endmodule

`default_nettype wire
