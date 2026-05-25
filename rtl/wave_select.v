`timescale 1ns / 1ps

module wave_select #(
    parameter [31:0] FREQ_WORD_0 = 32'd85899,
    parameter [31:0] FREQ_WORD_1 = 32'd429497,
    parameter [31:0] FREQ_WORD_2 = 32'd858993,
    parameter [31:0] FREQ_WORD_3 = 32'd1717987
)(
    input  wire clk,
    input  wire rst_n,
    input  wire key_wave_pulse,
    input  wire key_freq_pulse,
    output reg  [1:0] wave_sel,
    output reg  [1:0] freq_sel,
    output reg  [31:0] freq_word
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave_sel <= 2'd0;
        end else if (key_wave_pulse) begin
            if (wave_sel == 2'd2)
                wave_sel <= 2'd0;
            else
                wave_sel <= wave_sel + 2'd1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            freq_sel <= 2'd0;
        end else if (key_freq_pulse) begin
            freq_sel <= freq_sel + 2'd1;
        end
    end

    always @(*) begin
        case (freq_sel)
            2'd0: freq_word = FREQ_WORD_0;
            2'd1: freq_word = FREQ_WORD_1;
            2'd2: freq_word = FREQ_WORD_2;
            2'd3: freq_word = FREQ_WORD_3;
            default: freq_word = FREQ_WORD_0;
        endcase
    end

endmodule
