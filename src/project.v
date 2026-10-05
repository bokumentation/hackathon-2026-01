`default_nettype none

module tt_um_bokumentation_auth_boundary (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    localparam S_LOAD  = 2'd0;
    localparam S_KEY   = 2'd1;
    localparam S_START = 2'd2;
    localparam S_WAIT  = 2'd3;

    wire frame_bit = ui_in[0];
    wire load_en   = ui_in[1];
    wire fault_ack = ui_in[2];

    reg [1:0]   st;
    reg [191:0] sr;
    reg [7:0]   bit_count;
    reg         key_load_q;
    reg         start_q;

    wire [63:0] key     = sr[191:128];
    wire [31:0] counter = sr[127:96];
    wire [63:0] payload = sr[95:32];
    wire [31:0] tag_in  = sr[31:0];

    wire        host_full;
    wire [95:0] host_data_q;
    wire        fault;
    wire        auth_ok;
    wire        fresh_ok;
    wire        done;

    salaras_auth_top core (
        .clk(clk),
        .rst_n(rst_n),
        .key(key),
        .key_load(key_load_q),
        .counter(counter),
        .payload(payload),
        .tag_in(tag_in),
        .start(start_q),
        .fault_ack(fault_ack),
        .host_full(host_full),
        .host_data_q(host_data_q),
        .fault(fault),
        .auth_ok(auth_ok),
        .fresh_ok(fresh_ok),
        .done(done)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st         <= S_LOAD;
            sr         <= 192'd0;
            bit_count  <= 8'd0;
            key_load_q <= 1'b0;
            start_q    <= 1'b0;
        end else begin
            key_load_q <= 1'b0;
            start_q    <= 1'b0;

            case (st)
                S_LOAD: begin
                    if (load_en) begin
                        sr        <= {sr[190:0], frame_bit};
                        bit_count <= bit_count + 8'd1;
                        if (bit_count == 8'd191) begin
                            st <= S_KEY;
                        end
                    end else begin
                        bit_count <= 8'd0;
                    end
                end

                S_KEY: begin
                    key_load_q <= 1'b1;
                    st         <= S_START;
                end

                S_START: begin
                    start_q <= 1'b1;
                    st      <= S_WAIT;
                end

                S_WAIT: begin
                    if (done) begin
                        st <= S_LOAD;
                    end
                end

                default: st <= S_LOAD;
            endcase
        end
    end

    assign uo_out  = {done, host_full, fault, auth_ok, fresh_ok, 3'b000};
    assign uio_out = {6'b000000, fault, host_full};
    assign uio_oe  = 8'b00000011;

    wire _unused = &{1'b0, uio_in, ui_in[7:3], ena, host_data_q};
endmodule

`default_nettype wire
