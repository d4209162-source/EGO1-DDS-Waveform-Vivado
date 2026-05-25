`timescale 1ns / 1ps

module key_debounce #(
    parameter integer DEBOUNCE_MAX = 1_000_000,
    parameter KEY_ACTIVE_LOW = 1
)(
    input  wire clk,
    input  wire rst_n,
    input  wire key_in,
    output reg  key_pulse,
    output wire key_level
);

    reg key_sync0;
    reg key_sync1;
    reg key_stable;
    reg key_stable_d;
    reg [31:0] cnt;

    wire pressed_now;
    wire pressed_last;

    assign key_level    = key_stable;
    assign pressed_now  = KEY_ACTIVE_LOW ? ~key_stable   : key_stable;
    assign pressed_last = KEY_ACTIVE_LOW ? ~key_stable_d : key_stable_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sync0 <= KEY_ACTIVE_LOW ? 1'b1 : 1'b0;
            key_sync1 <= KEY_ACTIVE_LOW ? 1'b1 : 1'b0;
        end else begin
            key_sync0 <= key_in;
            key_sync1 <= key_sync0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stable <= KEY_ACTIVE_LOW ? 1'b1 : 1'b0;
            cnt        <= 32'd0;
        end else begin
            if (key_sync1 == key_stable) begin
                cnt <= 32'd0;
            end else begin
                if (cnt >= DEBOUNCE_MAX - 1) begin
                    key_stable <= key_sync1;
                    cnt        <= 32'd0;
                end else begin
                    cnt <= cnt + 32'd1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stable_d <= KEY_ACTIVE_LOW ? 1'b1 : 1'b0;
            key_pulse    <= 1'b0;
        end else begin
            key_stable_d <= key_stable;
            key_pulse    <= pressed_now & ~pressed_last;
        end
    end

endmodule
