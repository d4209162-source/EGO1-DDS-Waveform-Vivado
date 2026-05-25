`timescale 1ns / 1ps

module sys_fsm(
    input  wire clk,
    input  wire rst_n,
    input  wire key_start_pulse,
    output wire phase_enable,
    output reg  [1:0] state
);

    localparam ST_IDLE = 2'd0;
    localparam ST_RUN  = 2'd1;
    localparam ST_HOLD = 2'd2;

    assign phase_enable = (state == ST_RUN);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (key_start_pulse)
                        state <= ST_RUN;
                end
                ST_RUN: begin
                    if (key_start_pulse)
                        state <= ST_HOLD;
                end
                ST_HOLD: begin
                    if (key_start_pulse)
                        state <= ST_RUN;
                end
                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
