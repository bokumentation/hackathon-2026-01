`default_nettype none
`include "salaras_rx_defs.svh"

module frame_capture (
    input  wire clk,
    input  wire rst_n,
    input  wire reset_capture,
    input  wire serial_clock,
    input  wire serial_data,
    output wire header_ok,
    output wire payload_valid,
    output wire payload_bit,
    output wire [7:0] payload_index,
    output wire frame_done,
    output wire [`SRX_PAYLOAD_BITS-1:0] payload_q
);
    reg [`SRX_HEADER_BITS-1:0]  header_sr;
    reg [`SRX_PAYLOAD_BITS-1:0] payload_sr;
    reg [7:0] bit_count;
    reg       in_payload;
    reg       done_flag;
    reg       frame_strobe;

    wire [31:0] preamble = header_sr[95:64];
    wire [15:0] type_1   = header_sr[63:48];
    wire [15:0] type_2   = header_sr[47:32];
    wire [31:0] constant = header_sr[31:0];

    wire [3:0] validations;

    assign header_ok = &validations;

    data_validate u_validate (
        .preamble(preamble),
        .type_1(type_1),
        .type_2(type_2),
        .constant(constant),
        .validations(validations)
    );

    assign payload_valid = serial_clock & in_payload & ~done_flag;
    assign payload_bit   = serial_data;
    assign payload_index = bit_count;
    assign frame_done    = frame_strobe;
    assign payload_q     = payload_sr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            header_sr    <= {`SRX_HEADER_BITS{1'b0}};
            payload_sr   <= {`SRX_PAYLOAD_BITS{1'b0}};
            bit_count    <= 8'd0;
            in_payload   <= 1'b0;
            done_flag    <= 1'b0;
            frame_strobe <= 1'b0;
        end else if (reset_capture) begin
            header_sr    <= {`SRX_HEADER_BITS{1'b0}};
            payload_sr   <= {`SRX_PAYLOAD_BITS{1'b0}};
            bit_count    <= 8'd0;
            in_payload   <= 1'b0;
            done_flag    <= 1'b0;
            frame_strobe <= 1'b0;
        end else begin
            frame_strobe <= 1'b0;
            if (serial_clock) begin
                if (!in_payload) begin
                    header_sr <= {header_sr[`SRX_HEADER_BITS-2:0], serial_data};
                    if (header_ok) begin
                        in_payload <= 1'b1;
                        bit_count  <= 8'd0;
                    end
                end else if (!done_flag) begin
                    payload_sr <= {payload_sr[`SRX_PAYLOAD_BITS-2:0], serial_data};
                    if (bit_count == 8'd95) begin
                        done_flag    <= 1'b1;
                        frame_strobe <= 1'b1;
                    end else begin
                        bit_count <= bit_count + 8'd1;
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire
