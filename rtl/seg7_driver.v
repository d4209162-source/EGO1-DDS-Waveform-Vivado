`timescale 1ns / 1ps

module seg7_driver #(
    parameter integer SCAN_DIV = 50_000,
    parameter SEG_ACTIVE_LOW = 1,
    parameter SEL_ACTIVE_LOW = 1
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [1:0] state,
    input  wire [1:0] wave_sel,
    input  wire [1:0] freq_sel,
    output wire [7:0] seg,
    output wire [3:0] sel
);

    reg [31:0] scan_cnt;
    reg [1:0]  scan_idx;
    reg [3:0]  digit_data;
    reg [7:0] seg_raw;
    reg [3:0] sel_raw;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt <= 32'd0;
            scan_idx <= 2'd0;
        end else begin
            if (scan_cnt >= SCAN_DIV - 1) begin
                scan_cnt <= 32'd0;
                scan_idx <= scan_idx + 2'd1;
            end else begin
                scan_cnt <= scan_cnt + 32'd1;
            end
        end
    end

    always @(*) begin
        case (scan_idx)
            2'd0: begin sel_raw = 4'b0001; digit_data = {2'b00, state}; end
            2'd1: begin sel_raw = 4'b0010; digit_data = {2'b00, wave_sel}; end
            2'd2: begin sel_raw = 4'b0100; digit_data = {2'b00, freq_sel}; end
            2'd3: begin sel_raw = 4'b1000; digit_data = 4'hF; end
            default: begin sel_raw = 4'b0001; digit_data = 4'h0; end
        endcase
    end

    // raw encoding: seg_raw[6:0] = abcdefg, seg_raw[7] = dp
    always @(*) begin
        case (digit_data)
            4'h0: seg_raw = 8'b0011_1111;
            4'h1: seg_raw = 8'b0000_0110;
            4'h2: seg_raw = 8'b0101_1011;
            4'h3: seg_raw = 8'b0100_1111;
            4'h4: seg_raw = 8'b0110_0110;
            4'h5: seg_raw = 8'b0110_1101;
            4'h6: seg_raw = 8'b0111_1101;
            4'h7: seg_raw = 8'b0000_0111;
            4'h8: seg_raw = 8'b0111_1111;
            4'h9: seg_raw = 8'b0110_1111;
            4'hA: seg_raw = 8'b0111_0111;
            4'hB: seg_raw = 8'b0111_1100;
            4'hC: seg_raw = 8'b0011_1001;
            4'hD: seg_raw = 8'b0101_1110;
            4'hE: seg_raw = 8'b0111_1001;
            default: seg_raw = 8'b0000_0000;
        endcase
    end

    assign seg = SEG_ACTIVE_LOW ? ~seg_raw : seg_raw;
    assign sel = SEL_ACTIVE_LOW ? ~sel_raw : sel_raw;

endmodule
