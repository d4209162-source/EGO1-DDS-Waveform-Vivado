`timescale 1ns / 1ps

// ============================================================
// tb_top_dds_wavegen.v
// Report-friendly simulation testbench.
// ============================================================

module tb_top_dds_wavegen;

    reg clk;
    reg rst_n;
    reg key_start;
    reg key_wave;
    reg key_freq;

    wire dac_clk;
    wire [7:0] dac_data;
    wire [7:0] seg;
    wire [3:0] sel;
    wire [2:0] wave_led;
    wire [2:0] state_led;
    // 仅用于仿真观察：方波阶段标志
    wire square_stage;
    assign square_stage = (wave_led == 3'b010);

    // 仅用于仿真观察：DAC最高位，方波时可直接看成 0/1 方波
    wire dac_square_view;
    assign dac_square_view = dac_data[7];

    // Debug signals for simulation report
    wire [1:0] dbg_wave_sel_from_select;
    wire [1:0] dbg_wave_sel_into_dds;
    wire [7:0] dbg_square_data;
    wire [7:0] dbg_triangle_data;
    wire [7:0] dbg_wave_data;
    wire       dbg_square_bit;

    assign dbg_wave_sel_from_select = dut.u_wave_select.wave_sel;
    assign dbg_wave_sel_into_dds    = dut.u_dds_core_fixed.wave_sel;
    assign dbg_square_data          = dut.u_dds_core_fixed.square_data;
    assign dbg_triangle_data        = dut.u_dds_core_fixed.triangle_data;
    assign dbg_wave_data            = dut.u_dds_core_fixed.wave_data;
    assign dbg_square_bit           = dac_data[7];

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    top_dds_wavegen #(
        .DEBOUNCE_MAX(4),
        .SEG_SCAN_DIV(20),
        .KEY_ACTIVE_LOW(1),
        .SEG_ACTIVE_LOW(1),
        .SEL_ACTIVE_LOW(1),
        .FREQ_WORD_0(32'h0040_0000),
        .FREQ_WORD_1(32'h0040_0000),
        .FREQ_WORD_2(32'h0040_0000),
        .FREQ_WORD_3(32'h0040_0000)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .key_start(key_start),
        .key_wave(key_wave),
        .key_freq(key_freq),
        .dac_clk(dac_clk),
        .dac_data(dac_data),
        .seg(seg),
        .sel(sel),
        .wave_led(wave_led),
        .state_led(state_led)
    );

    initial begin
        rst_n     = 1'b0;
        key_start = 1'b1;
        key_wave  = 1'b1;
        key_freq  = 1'b1;

        #100;
        rst_n = 1'b1;

        #200;
        press_key_start();    // IDLE -> RUN

        #30000;               // sine, wave_led = 001

        press_key_wave();     // sine -> square
        #30000;               // square, wave_led = 010

        press_key_wave();     // square -> triangle
        #30000;               // triangle, wave_led = 100

        press_key_start();    // RUN -> HOLD
        #10000;

        $finish;
    end

    // Runtime check: square stage must be 00/FF only.
    always @(posedge clk) begin
        if (rst_n && state_led == 3'b010 && wave_led == 3'b010) begin
            if (dac_data !== 8'h00 && dac_data !== 8'hFF) begin
                $display("ERROR at %0t ns: Square wave stage, but dac_data = %h", $time, dac_data);
            end
        end
    end

    task press_key_start;
    begin
        key_start = 1'b0;
        #200;
        key_start = 1'b1;
        #500;
    end
    endtask

    task press_key_wave;
    begin
        key_wave = 1'b0;
        #200;
        key_wave = 1'b1;
        #500;
    end
    endtask

endmodule
