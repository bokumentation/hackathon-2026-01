module l1_formal (
    input wire clk,
    input wire rst_n,
    input wire pos_edge,
    input wire neg_edge,
    input wire transmission_begin
);
    wire framing_ok;
    wire timing_fault;
    wire timeout_fault;

    l1_framing_validator dut (
        .clk(clk),
        .rst_n(rst_n),
        .pos_edge(pos_edge),
        .neg_edge(neg_edge),
        .transmission_begin(transmission_begin),
        .framing_ok(framing_ok),
        .timing_fault(timing_fault),
        .timeout_fault(timeout_fault)
    );

    always @(posedge clk) begin
        if (rst_n) begin
            assert (!framing_ok || (!timing_fault && !timeout_fault));
        end
    end
endmodule
