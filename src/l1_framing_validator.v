`default_nettype none
`include "salaras_rx_defs.svh"

module l1_framing_validator (
    input  wire clk,
    input  wire rst_n,
    input  wire pos_edge,
    input  wire neg_edge,
    input  wire transmission_begin,
    output wire framing_ok,
    output wire timing_fault,
    output wire timeout_fault
);
    wire any_edge = pos_edge | neg_edge;

    reg [15:0] edge_timer;
    reg        in_frame;
    reg        have_prev;
    reg        timing_fault_q;
    reg        timeout_fault_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_timer      <= 16'd0;
            in_frame        <= 1'b0;
            have_prev       <= 1'b0;
            timing_fault_q  <= 1'b0;
            timeout_fault_q <= 1'b0;
        end else begin
            if (transmission_begin) begin
                in_frame        <= 1'b1;
                have_prev       <= 1'b0;
                edge_timer      <= 16'd0;
                timing_fault_q  <= 1'b0;
                timeout_fault_q <= 1'b0;
            end else if (any_edge) begin
                if (have_prev) begin
                    if ((edge_timer < (`SRX_HALF_PERIOD - `SRX_TIMING_TOLERANCE)) ||
                        (edge_timer > (`SRX_HALF_PERIOD + `SRX_TIMING_TOLERANCE))) begin
                        timing_fault_q <= 1'b1;
                    end
                end
                have_prev  <= 1'b1;
                edge_timer <= 16'd1;
            end else if (in_frame) begin
                edge_timer <= edge_timer + 16'd1;
                if (edge_timer >= `SRX_TIMEOUT_CYCLES) begin
                    timeout_fault_q <= 1'b1;
                end
            end else begin
                edge_timer <= 16'd0;
            end
        end
    end

    assign framing_ok    = in_frame & ~(timing_fault_q | timeout_fault_q);
    assign timing_fault  = timing_fault_q;
    assign timeout_fault = timeout_fault_q;
endmodule

`default_nettype wire
