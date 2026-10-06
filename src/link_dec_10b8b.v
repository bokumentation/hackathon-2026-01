`default_nettype none

module link_dec_10b8b (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid,
    input  wire [9:0] din,
    output reg  [7:0] dout,
    output reg        is_k,
    output reg        dout_valid,
    output reg        code_error,
    output reg        disp_error
);
    reg rd;

    wire [5:0] e6 = din[9:4];
    wire [3:0] e4 = din[3:0];

    function [5:0] x_rdn;
        input [5:0] v;
        case (v)
            6'b001011: x_rdn = {1'b1, 5'd20};
            6'b001101: x_rdn = {1'b1, 5'd12};
            6'b001110: x_rdn = {1'b1, 5'd28};
            6'b001111: x_rdn = {1'b1, 5'd28};
            6'b010011: x_rdn = {1'b1, 5'd18};
            6'b010101: x_rdn = {1'b1, 5'd10};
            6'b010110: x_rdn = {1'b1, 5'd26};
            6'b010111: x_rdn = {1'b1, 5'd15};
            6'b011001: x_rdn = {1'b1, 5'd6};
            6'b011010: x_rdn = {1'b1, 5'd22};
            6'b011011: x_rdn = {1'b1, 5'd16};
            6'b011100: x_rdn = {1'b1, 5'd14};
            6'b011101: x_rdn = {1'b1, 5'd1};
            6'b011110: x_rdn = {1'b1, 5'd30};
            6'b100011: x_rdn = {1'b1, 5'd17};
            6'b100101: x_rdn = {1'b1, 5'd9};
            6'b100110: x_rdn = {1'b1, 5'd25};
            6'b100111: x_rdn = {1'b1, 5'd0};
            6'b101001: x_rdn = {1'b1, 5'd5};
            6'b101010: x_rdn = {1'b1, 5'd21};
            6'b101011: x_rdn = {1'b1, 5'd31};
            6'b101100: x_rdn = {1'b1, 5'd13};
            6'b101101: x_rdn = {1'b1, 5'd2};
            6'b101110: x_rdn = {1'b1, 5'd29};
            6'b110001: x_rdn = {1'b1, 5'd3};
            6'b110010: x_rdn = {1'b1, 5'd19};
            6'b110011: x_rdn = {1'b1, 5'd24};
            6'b110100: x_rdn = {1'b1, 5'd11};
            6'b110101: x_rdn = {1'b1, 5'd4};
            6'b110110: x_rdn = {1'b1, 5'd27};
            6'b111000: x_rdn = {1'b1, 5'd7};
            6'b111001: x_rdn = {1'b1, 5'd8};
            6'b111010: x_rdn = {1'b1, 5'd23};
            default:   x_rdn = 6'd0;
        endcase
    endfunction

    function [5:0] x_rdp;
        input [5:0] v;
        case (v)
            6'b000101: x_rdp = {1'b1, 5'd23};
            6'b000110: x_rdp = {1'b1, 5'd8};
            6'b000111: x_rdp = {1'b1, 5'd7};
            6'b001001: x_rdp = {1'b1, 5'd27};
            6'b001010: x_rdp = {1'b1, 5'd4};
            6'b001011: x_rdp = {1'b1, 5'd20};
            6'b001100: x_rdp = {1'b1, 5'd24};
            6'b001101: x_rdp = {1'b1, 5'd12};
            6'b001110: x_rdp = {1'b1, 5'd28};
            6'b010010: x_rdp = {1'b1, 5'd2};
            6'b010011: x_rdp = {1'b1, 5'd18};
            6'b010100: x_rdp = {1'b1, 5'd31};
            6'b010101: x_rdp = {1'b1, 5'd10};
            6'b010110: x_rdp = {1'b1, 5'd26};
            6'b011000: x_rdp = {1'b1, 5'd0};
            6'b011001: x_rdp = {1'b1, 5'd6};
            6'b011010: x_rdp = {1'b1, 5'd22};
            6'b011100: x_rdp = {1'b1, 5'd14};
            6'b011110: x_rdp = {1'b1, 5'd30};
            6'b100010: x_rdp = {1'b1, 5'd1};
            6'b100011: x_rdp = {1'b1, 5'd17};
            6'b100100: x_rdp = {1'b1, 5'd16};
            6'b100101: x_rdp = {1'b1, 5'd9};
            6'b100110: x_rdp = {1'b1, 5'd25};
            6'b101000: x_rdp = {1'b1, 5'd15};
            6'b101001: x_rdp = {1'b1, 5'd5};
            6'b101010: x_rdp = {1'b1, 5'd21};
            6'b101100: x_rdp = {1'b1, 5'd13};
            6'b101110: x_rdp = {1'b1, 5'd29};
            6'b110000: x_rdp = {1'b1, 5'd28};
            6'b110001: x_rdp = {1'b1, 5'd3};
            6'b110010: x_rdp = {1'b1, 5'd19};
            6'b110100: x_rdp = {1'b1, 5'd11};
            default:   x_rdp = 6'd0;
        endcase
    endfunction

    function [3:0] y_rdn;
        input [3:0] v;
        case (v)
            4'b0101: y_rdn = {1'b1, 3'd2};
            4'b0110: y_rdn = {1'b1, 3'd6};
            4'b0111: y_rdn = {1'b1, 3'd7};
            4'b1001: y_rdn = {1'b1, 3'd1};
            4'b1010: y_rdn = {1'b1, 3'd5};
            4'b1011: y_rdn = {1'b1, 3'd0};
            4'b1100: y_rdn = {1'b1, 3'd3};
            4'b1101: y_rdn = {1'b1, 3'd4};
            4'b1110: y_rdn = {1'b1, 3'd7};
            default:   y_rdn = 4'd0;
        endcase
    endfunction

    function [3:0] y_rdp;
        input [3:0] v;
        case (v)
            4'b0001: y_rdp = {1'b1, 3'd7};
            4'b0010: y_rdp = {1'b1, 3'd4};
            4'b0011: y_rdp = {1'b1, 3'd3};
            4'b0100: y_rdp = {1'b1, 3'd0};
            4'b0101: y_rdp = {1'b1, 3'd2};
            4'b0110: y_rdp = {1'b1, 3'd6};
            4'b1000: y_rdp = {1'b1, 3'd7};
            4'b1001: y_rdp = {1'b1, 3'd1};
            4'b1010: y_rdp = {1'b1, 3'd5};
            default:   y_rdp = 4'd0;
        endcase
    endfunction

    function [3:0] ky_rdn;
        input [3:0] v;
        case (v)
            4'b0101: ky_rdn = {1'b1, 3'd5};
            4'b0110: ky_rdn = {1'b1, 3'd1};
            4'b0111: ky_rdn = {1'b1, 3'd7};
            4'b1001: ky_rdn = {1'b1, 3'd6};
            4'b1010: ky_rdn = {1'b1, 3'd2};
            4'b1011: ky_rdn = {1'b1, 3'd0};
            4'b1100: ky_rdn = {1'b1, 3'd3};
            4'b1101: ky_rdn = {1'b1, 3'd4};
            default:   ky_rdn = 4'd0;
        endcase
    endfunction

    function [3:0] ky_rdp;
        input [3:0] v;
        case (v)
            4'b0010: ky_rdp = {1'b1, 3'd4};
            4'b0011: ky_rdp = {1'b1, 3'd3};
            4'b0100: ky_rdp = {1'b1, 3'd0};
            4'b0101: ky_rdp = {1'b1, 3'd2};
            4'b0110: ky_rdp = {1'b1, 3'd6};
            4'b1000: ky_rdp = {1'b1, 3'd7};
            4'b1001: ky_rdp = {1'b1, 3'd1};
            4'b1010: ky_rdp = {1'b1, 3'd5};
            default:   ky_rdp = 4'd0;
        endcase
    endfunction

    function [2:0] ones6;
        input [5:0] v;
        ones6 = {2'b0, v[0]} + {2'b0, v[1]} + {2'b0, v[2]} + {2'b0, v[3]} + {2'b0, v[4]} + {2'b0, v[5]};
    endfunction

    function [1:0] ones4;
        input [3:0] v;
        ones4 = {1'b0, v[0]} + {1'b0, v[1]} + {1'b0, v[2]} + {1'b0, v[3]};
    endfunction

    wire [5:0] xr_n = x_rdn(e6);
    wire [5:0] xr_p = x_rdp(e6);
    wire k28_rdn = (e6 == 6'b001111);
    wire k28_rdp = (e6 == 6'b110000);

    wire [5:0] x_exp = rd ? xr_p : xr_n;
    wire [5:0] x_opp = rd ? xr_n : xr_p;
    wire k28_exp = rd ? k28_rdp : k28_rdn;
    wire k28_opp = rd ? k28_rdn : k28_rdp;
    wire six_ok  = k28_exp || x_exp[5];
    wire six_opp = k28_opp || x_opp[5];

    wire [4:0] x = k28_exp ? 5'd28 : x_exp[4:0];
    wire rd_mid  = (ones6(e6) == 3'd3) ? rd : ~rd;
    wire k_other = (x == 5'd23 || x == 5'd27 || x == 5'd29 || x == 5'd30) &&
                   ((rd_mid == 1'b0 && e4 == 4'b0111) || (rd_mid == 1'b1 && e4 == 4'b1000));
    wire is_k_any = k28_exp || k_other;

    wire [3:0] y_exp = is_k_any ? (rd_mid ? ky_rdp(e4) : ky_rdn(e4))
                                : (rd_mid ? y_rdp(e4)  : y_rdn(e4));
    wire [3:0] y_opp = is_k_any ? (rd_mid ? ky_rdn(e4) : ky_rdp(e4))
                                : (rd_mid ? y_rdn(e4)  : y_rdp(e4));
    wire four_ok  = y_exp[3];
    wire four_opp = y_opp[3];

    wire is_k_x = is_k_any;

    wire rd_next = (ones4(e4) == 2'd2) ? rd_mid : ~rd_mid;
    wire _unused = &{1'b0, x_opp[4:0], y_opp[2:0]};
    wire err_now = ~(six_ok && four_ok);
    wire err_opp = (six_opp && four_opp);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd         <= 1'b0;
            dout       <= 8'd0;
            is_k       <= 1'b0;
            dout_valid <= 1'b0;
            code_error <= 1'b0;
            disp_error <= 1'b0;
        end else begin
            dout_valid <= valid;
            code_error <= 1'b0;
            disp_error <= 1'b0;
            if (valid) begin
                dout <= {y_exp[2:0], x};
                is_k <= is_k_x;
                if (err_now) begin
                    if (err_opp) disp_error <= 1'b1;
                    else         code_error <= 1'b1;
                end
                rd <= rd_next;
            end
        end
    end
endmodule

`default_nettype wire
