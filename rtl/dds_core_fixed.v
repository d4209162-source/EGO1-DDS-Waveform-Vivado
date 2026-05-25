`timescale 1ns / 1ps

// ============================================================
// dds_core_fixed.v
// DDS core for sine / square / triangle waveform generation.
// Supports independent amplitude control for three waveforms.
//
// wave_sel mapping:
//   2'd0 : sine
//   2'd1 : square
//   2'd2 : triangle
//
// Amplitude scale:
//   9'd256 : 100% amplitude
//   9'd192 : 75% amplitude
//   9'd128 : 50% amplitude
//   9'd64  : 25% amplitude
//   9'd0   : output fixed at 128
//
// Formula:
//   wave_data = 128 + (raw_wave - 128) * amp_scale / 256
// ============================================================

module dds_core_fixed #(
    parameter [8:0] SINE_AMP_SCALE     = 9'd256,
    parameter [8:0] SQUARE_AMP_SCALE   = 9'd256,
    parameter [8:0] TRIANGLE_AMP_SCALE = 9'd256
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [31:0] freq_word,
    input  wire [1:0]  wave_sel,
    output reg  [7:0]  wave_data,
    output wire [31:0] phase_debug
);

    reg [31:0] phase_acc;

    wire [7:0] phase_addr;
    wire [7:0] sine_data;
    wire [7:0] square_data;
    wire [7:0] triangle_data;

    reg  [7:0] raw_wave;
    reg  [8:0] amp_scale;

    wire signed [8:0]  centered_wave;
    wire signed [18:0] multiplied_wave;
    wire signed [10:0] scaled_wave;
    wire signed [11:0] shifted_wave;

    assign phase_addr  = phase_acc[31:24];
    assign phase_debug = phase_acc;

    // ------------------------------------------------------------
    // Square wave
    // Full-scale square wave only has two values: 255 and 0.
    // After amplitude scaling, it becomes smaller around center 128.
    // Example:
    //   100%: 255 / 0
    //   50% : 192 / 64
    // ------------------------------------------------------------
    assign square_data = (phase_acc[31] == 1'b0) ? 8'd255 : 8'd0;

    // ------------------------------------------------------------
    // Triangle wave
    // Rising in first half cycle, falling in second half cycle.
    // ------------------------------------------------------------
    assign triangle_data = (phase_addr[7] == 1'b0) ?
                           {phase_addr[6:0], 1'b0} :
                           (8'd255 - {phase_addr[6:0], 1'b0});

    // ------------------------------------------------------------
    // Sine lookup table
    // ------------------------------------------------------------
    sin_lut_256x8 u_sin_lut_256x8 (
        .addr(phase_addr),
        .data(sine_data)
    );

    // ------------------------------------------------------------
    // DDS phase accumulator
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'd0;
        end else if (enable) begin
            phase_acc <= phase_acc + freq_word;
        end
    end

    // ------------------------------------------------------------
    // Select raw waveform and corresponding amplitude scale
    // ------------------------------------------------------------
    always @(*) begin
        case (wave_sel)
            2'd0: begin
                raw_wave  = sine_data;
                amp_scale = SINE_AMP_SCALE;
            end

            2'd1: begin
                raw_wave  = square_data;
                amp_scale = SQUARE_AMP_SCALE;
            end

            2'd2: begin
                raw_wave  = triangle_data;
                amp_scale = TRIANGLE_AMP_SCALE;
            end

            default: begin
                raw_wave  = sine_data;
                amp_scale = SINE_AMP_SCALE;
            end
        endcase
    end

    // ------------------------------------------------------------
    // Independent digital amplitude control
    //
    // raw_wave is unsigned 0~255.
    // 128 is the center level.
    //
    // Step 1: raw_wave - 128
    // Step 2: multiply by amp_scale
    // Step 3: divide by 256 using arithmetic shift
    // Step 4: add 128 back
    // ------------------------------------------------------------
    assign centered_wave   = $signed({1'b0, raw_wave}) - 9'sd128;
    assign multiplied_wave = centered_wave * $signed({1'b0, amp_scale});
    assign scaled_wave     = multiplied_wave >>> 8;
    assign shifted_wave    = 12'sd128 + scaled_wave;

    // ------------------------------------------------------------
    // Saturation protection
    // ------------------------------------------------------------
    always @(*) begin
        if (shifted_wave < 0) begin
            wave_data = 8'd0;
        end else if (shifted_wave > 255) begin
            wave_data = 8'd255;
        end else begin
            wave_data = shifted_wave[7:0];
        end
    end

endmodule