`timescale 1ns / 1ps

// ============================================================
// top_dds_wavegen.v
// Top module for DDS sine / square / triangle generator.
// Supports independent amplitude control for each waveform.
//
// Current amplitude setting:
//   sine     : 100%
//   square   : 50%
//   triangle : 25%
// ============================================================

module top_dds_wavegen #(
    parameter integer DEBOUNCE_MAX = 1_000_000,
    parameter integer SEG_SCAN_DIV = 50_000,
    parameter KEY_ACTIVE_LOW = 1,
    parameter SEG_ACTIVE_LOW = 1,
    parameter SEL_ACTIVE_LOW = 1,

    parameter [31:0] FREQ_WORD_0 = 32'd85899,
    parameter [31:0] FREQ_WORD_1 = 32'd429497,
    parameter [31:0] FREQ_WORD_2 = 32'd858993,
    parameter [31:0] FREQ_WORD_3 = 32'd1717987,

    // ------------------------------------------------------------
    // Independent amplitude control
    // 9'd256 : 100%
    // 9'd192 : 75%
    // 9'd128 : 50%
    // 9'd64  : 25%
    // ------------------------------------------------------------
    parameter [8:0] SINE_AMP_SCALE     = 9'd256,
    parameter [8:0] SQUARE_AMP_SCALE   = 9'd128,
    parameter [8:0] TRIANGLE_AMP_SCALE = 9'd64
)(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       key_start,
    input  wire       key_wave,
    input  wire       key_freq,

    output wire       dac_clk,
    output wire [7:0] dac_data,

    output wire [7:0] seg,
    output wire [3:0] sel,

    output wire [2:0] wave_led,
    output wire [2:0] state_led
);

    wire key_start_pulse;
    wire key_wave_pulse;
    wire key_freq_pulse;

    wire phase_enable;

    wire [1:0] state;
    wire [1:0] wave_sel;
    wire [1:0] freq_sel;

    wire [31:0] freq_word;
    wire [7:0]  wave_data;

    assign dac_clk  = clk;
    assign dac_data = wave_data;

    // ------------------------------------------------------------
    // Start / pause key debounce
    // ------------------------------------------------------------
    key_debounce #(
        .DEBOUNCE_MAX(DEBOUNCE_MAX),
        .KEY_ACTIVE_LOW(KEY_ACTIVE_LOW)
    ) u_key_start (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(key_start),
        .key_pulse(key_start_pulse),
        .key_level()
    );

    // ------------------------------------------------------------
    // Waveform select key debounce
    // ------------------------------------------------------------
    key_debounce #(
        .DEBOUNCE_MAX(DEBOUNCE_MAX),
        .KEY_ACTIVE_LOW(KEY_ACTIVE_LOW)
    ) u_key_wave (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(key_wave),
        .key_pulse(key_wave_pulse),
        .key_level()
    );

    // ------------------------------------------------------------
    // Frequency select key debounce
    // ------------------------------------------------------------
    key_debounce #(
        .DEBOUNCE_MAX(DEBOUNCE_MAX),
        .KEY_ACTIVE_LOW(KEY_ACTIVE_LOW)
    ) u_key_freq (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(key_freq),
        .key_pulse(key_freq_pulse),
        .key_level()
    );

    // ------------------------------------------------------------
    // Main FSM
    // state:
    //   2'd0 -> IDLE
    //   2'd1 -> RUN
    //   2'd2 -> HOLD
    // ------------------------------------------------------------
    sys_fsm u_sys_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .key_start_pulse(key_start_pulse),
        .phase_enable(phase_enable),
        .state(state)
    );

    // ------------------------------------------------------------
    // Waveform and frequency selector
    // wave_sel:
    //   2'd0 -> sine
    //   2'd1 -> square
    //   2'd2 -> triangle
    // ------------------------------------------------------------
    wave_select #(
        .FREQ_WORD_0(FREQ_WORD_0),
        .FREQ_WORD_1(FREQ_WORD_1),
        .FREQ_WORD_2(FREQ_WORD_2),
        .FREQ_WORD_3(FREQ_WORD_3)
    ) u_wave_select (
        .clk(clk),
        .rst_n(rst_n),
        .key_wave_pulse(key_wave_pulse),
        .key_freq_pulse(key_freq_pulse),
        .wave_sel(wave_sel),
        .freq_sel(freq_sel),
        .freq_word(freq_word)
    );

    // ------------------------------------------------------------
    // DDS core with independent amplitude control
    // ------------------------------------------------------------
    dds_core_fixed #(
        .SINE_AMP_SCALE(SINE_AMP_SCALE),
        .SQUARE_AMP_SCALE(SQUARE_AMP_SCALE),
        .TRIANGLE_AMP_SCALE(TRIANGLE_AMP_SCALE)
    ) u_dds_core_fixed (
        .clk(clk),
        .rst_n(rst_n),
        .enable(phase_enable),
        .freq_word(freq_word),
        .wave_sel(wave_sel),
        .wave_data(wave_data),
        .phase_debug()
    );

    // ------------------------------------------------------------
    // Seven-segment display driver
    // ------------------------------------------------------------
    seg7_driver #(
        .SCAN_DIV(SEG_SCAN_DIV),
        .SEG_ACTIVE_LOW(SEG_ACTIVE_LOW),
        .SEL_ACTIVE_LOW(SEL_ACTIVE_LOW)
    ) u_seg7_driver (
        .clk(clk),
        .rst_n(rst_n),
        .state(state),
        .wave_sel(wave_sel),
        .freq_sel(freq_sel),
        .seg(seg),
        .sel(sel)
    );

    // ------------------------------------------------------------
    // Waveform indicator LED
    // wave_led = 001 -> sine
    // wave_led = 010 -> square
    // wave_led = 100 -> triangle
    // ------------------------------------------------------------
    assign wave_led = (wave_sel == 2'd0) ? 3'b001 :
                      (wave_sel == 2'd1) ? 3'b010 :
                      (wave_sel == 2'd2) ? 3'b100 :
                                           3'b001;

    // ------------------------------------------------------------
    // State indicator LED
    // state_led = 001 -> IDLE
    // state_led = 010 -> RUN
    // state_led = 100 -> HOLD
    // ------------------------------------------------------------
    assign state_led = (state == 2'd0) ? 3'b001 :
                       (state == 2'd1) ? 3'b010 :
                       (state == 2'd2) ? 3'b100 :
                                         3'b001;

endmodule