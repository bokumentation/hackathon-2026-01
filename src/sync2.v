`default_nettype none

module sync2 (
    input  wire clk,
    input  wire rst_n,
    input  wire async_in,
    output wire sync_out
);
    reg meta;
    reg sync_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            meta   <= 1'b0;
            sync_q <= 1'b0;
        end else begin
            meta   <= async_in;
            sync_q <= meta;
        end
    end

    assign sync_out = sync_q;
endmodule

`default_nettype wire
