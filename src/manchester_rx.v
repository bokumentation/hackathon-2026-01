`default_nettype none
`include "salaras_rx_defs.svh"

module manchester_rx (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire digital_in,
    output wire manchester_clock,
    output wire manchester_data,
    output wire transmission_begin,
    output wire pos_edge,
    output wire neg_edge
);
    reg previous_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) previous_in <= 1'b0;
        else previous_in <= digital_in;
    end

    assign pos_edge = ~previous_in & digital_in;
    assign neg_edge = previous_in & ~digital_in;

    localparam S_ARMED   = 2'd0,
               S_TIMING  = 2'd1,
               S_LOOKING = 2'd2,
               S_FOUND   = 2'd3;

    reg [1:0] state;
    reg [3:0] timer;
    reg decoded;
    reg clock_mask;
    reg tx_begin;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_ARMED;
            timer      <= 4'd0;
            decoded    <= 1'b0;
            clock_mask <= 1'b0;
            tx_begin   <= 1'b0;
        end else if (enable) begin
            case (state)
                S_ARMED: begin
                    clock_mask <= 1'b0;
                    if (pos_edge) begin
                        tx_begin <= 1'b1;
                        timer    <= 4'd0;
                        state    <= S_TIMING;
                    end
                end
                S_TIMING: begin
                    tx_begin <= 1'b0;
                    if (timer > `SRX_QUARTER_PERIOD) begin
                        timer <= 4'd0;
                        state <= S_LOOKING;
                    end else begin
                        timer <= timer + 4'd1;
                    end
                end
                S_LOOKING: begin
                    if (pos_edge) begin
                        decoded    <= 1'b0;
                        clock_mask <= 1'b1;
                        timer      <= 4'd0;
                        state      <= S_FOUND;
                    end else if (neg_edge) begin
                        decoded    <= 1'b1;
                        clock_mask <= 1'b1;
                        timer      <= 4'd0;
                        state      <= S_FOUND;
                    end else if (timer >= `SRX_HALF_PERIOD) begin
                        timer <= 4'd0;
                        state <= S_ARMED;
                    end else begin
                        timer <= timer + 4'd1;
                    end
                end
                S_FOUND: begin
                    clock_mask <= 1'b0;
                    if (timer >= `SRX_QUARTER_PERIOD) begin
                        timer <= 4'd0;
                        state <= S_TIMING;
                    end else begin
                        timer <= timer + 4'd1;
                    end
                end
                default: state <= S_ARMED;
            endcase
        end
    end

    assign manchester_clock   = clock_mask;
    assign manchester_data    = decoded;
    assign transmission_begin = tx_begin;
endmodule

`default_nettype wire
