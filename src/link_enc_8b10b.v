`default_nettype none

module link_enc_8b10b (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid,
    input  wire       is_k,
    input  wire [7:0] din,
    output reg  [9:0] dout,
    output reg        dout_valid
);
    reg rd;

    wire [4:0] x = din[4:0];
    wire [2:0] y = din[7:5];

    function [5:0] e5_rdn;
        input [4:0] v;
        case (v)
             0: e5_rdn = 6'b100111;
             1: e5_rdn = 6'b011101;
             2: e5_rdn = 6'b101101;
             3: e5_rdn = 6'b110001;
             4: e5_rdn = 6'b110101;
             5: e5_rdn = 6'b101001;
             6: e5_rdn = 6'b011001;
             7: e5_rdn = 6'b111000;
             8: e5_rdn = 6'b111001;
             9: e5_rdn = 6'b100101;
            10: e5_rdn = 6'b010101;
            11: e5_rdn = 6'b110100;
            12: e5_rdn = 6'b001101;
            13: e5_rdn = 6'b101100;
            14: e5_rdn = 6'b011100;
            15: e5_rdn = 6'b010111;
            16: e5_rdn = 6'b011011;
            17: e5_rdn = 6'b100011;
            18: e5_rdn = 6'b010011;
            19: e5_rdn = 6'b110010;
            20: e5_rdn = 6'b001011;
            21: e5_rdn = 6'b101010;
            22: e5_rdn = 6'b011010;
            23: e5_rdn = 6'b111010;
            24: e5_rdn = 6'b110011;
            25: e5_rdn = 6'b100110;
            26: e5_rdn = 6'b010110;
            27: e5_rdn = 6'b110110;
            28: e5_rdn = 6'b001110;
            29: e5_rdn = 6'b101110;
            30: e5_rdn = 6'b011110;
            31: e5_rdn = 6'b101011;
        endcase
    endfunction

    function [5:0] e5_rdp;
        input [4:0] v;
        case (v)
             0: e5_rdp = 6'b011000;
             1: e5_rdp = 6'b100010;
             2: e5_rdp = 6'b010010;
             3: e5_rdp = 6'b110001;
             4: e5_rdp = 6'b001010;
             5: e5_rdp = 6'b101001;
             6: e5_rdp = 6'b011001;
             7: e5_rdp = 6'b000111;
             8: e5_rdp = 6'b000110;
             9: e5_rdp = 6'b100101;
            10: e5_rdp = 6'b010101;
            11: e5_rdp = 6'b110100;
            12: e5_rdp = 6'b001101;
            13: e5_rdp = 6'b101100;
            14: e5_rdp = 6'b011100;
            15: e5_rdp = 6'b101000;
            16: e5_rdp = 6'b100100;
            17: e5_rdp = 6'b100011;
            18: e5_rdp = 6'b010011;
            19: e5_rdp = 6'b110010;
            20: e5_rdp = 6'b001011;
            21: e5_rdp = 6'b101010;
            22: e5_rdp = 6'b011010;
            23: e5_rdp = 6'b000101;
            24: e5_rdp = 6'b001100;
            25: e5_rdp = 6'b100110;
            26: e5_rdp = 6'b010110;
            27: e5_rdp = 6'b001001;
            28: e5_rdp = 6'b001110;
            29: e5_rdp = 6'b101110;
            30: e5_rdp = 6'b011110;
            31: e5_rdp = 6'b010100;
        endcase
    endfunction

    function [3:0] e4_rdn;
        input [2:0] v;
        case (v)
            0: e4_rdn = 4'b1011;
            1: e4_rdn = 4'b1001;
            2: e4_rdn = 4'b0101;
            3: e4_rdn = 4'b1100;
            4: e4_rdn = 4'b1101;
            5: e4_rdn = 4'b1010;
            6: e4_rdn = 4'b0110;
            7: e4_rdn = 4'b1110;
        endcase
    endfunction

    function [3:0] e4_rdp;
        input [2:0] v;
        case (v)
            0: e4_rdp = 4'b0100;
            1: e4_rdp = 4'b1001;
            2: e4_rdp = 4'b0101;
            3: e4_rdp = 4'b0011;
            4: e4_rdp = 4'b0010;
            5: e4_rdp = 4'b1010;
            6: e4_rdp = 4'b0110;
            7: e4_rdp = 4'b0001;
        endcase
    endfunction

    function [3:0] k4_rdn;
        input [2:0] v;
        case (v)
            0: k4_rdn = 4'b1011;
            1: k4_rdn = 4'b0110;
            2: k4_rdn = 4'b1010;
            3: k4_rdn = 4'b1100;
            4: k4_rdn = 4'b1101;
            5: k4_rdn = 4'b0101;
            6: k4_rdn = 4'b1001;
            7: k4_rdn = 4'b0111;
        endcase
    endfunction

    function [3:0] k4_rdp;
        input [2:0] v;
        case (v)
            0: k4_rdp = 4'b0100;
            1: k4_rdp = 4'b1001;
            2: k4_rdp = 4'b0101;
            3: k4_rdp = 4'b0011;
            4: k4_rdp = 4'b0010;
            5: k4_rdp = 4'b1010;
            6: k4_rdp = 4'b0110;
            7: k4_rdp = 4'b1000;
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

    wire is_k28 = is_k && (x == 5'b11100);
    wire [5:0] s6 = is_k28 ? (rd ? 6'b110000 : 6'b001111)
                          : (rd ? e5_rdp(x) : e5_rdn(x));
    wire rd_mid = (ones6(s6) == 3'd3) ? rd : ~rd;
    wire a7    = (y == 3'b111) &&
                 ((rd_mid == 1'b0 && (x == 5'd17 || x == 5'd18 || x == 5'd20)) ||
                  (rd_mid == 1'b1 && (x == 5'd11 || x == 5'd13 || x == 5'd14)));
    wire [3:0] s4 = a7 ? (rd_mid ? 4'b1000 : 4'b0111)
                       : (is_k ? (rd_mid ? k4_rdp(y) : k4_rdn(y))
                               : (rd_mid ? e4_rdp(y) : e4_rdn(y)));
    wire rd_next = (ones4(s4) == 2'd2) ? rd_mid : ~rd_mid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd         <= 1'b0;
            dout       <= 10'd0;
            dout_valid <= 1'b0;
        end else begin
            dout_valid <= valid;
            if (valid) begin
                dout <= {s6, s4};
                rd   <= rd_next;
            end
        end
    end
endmodule

`default_nettype wire
