/* The VGA driver from a QSPI RAM as framebuffer with 4 bit width.
 * It reads the pixel values from the QSPI RAM and outputs them.
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (c) 2024 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 * SPDX-License-Identifier: Apache-2.0
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : vga.v
 * Create   : Jul 28, 2024
 * Revise   : Jul 28, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */

`default_nettype none

module vga_qspi_framebuffer #(
    parameter LINE_VISIBLE      = 640,
    parameter LINE_FRONT_PORCH  = 16,
    parameter LINE_SYNC_PULSE   = 96,
    parameter LINE_BACK_PORCH   = 48,

    parameter ROW_VISIBLE       = 480,
    parameter ROW_FRONT_PORCH   = 10,
    parameter ROW_SYNC_PULSE    = 2,
    parameter ROW_BACK_PORCH    = 33
) (
    /* General signals */
    input  wire                             clk,                    // clock
    input  wire                             rst_n,                  // low active reset, already synchronized to the clock

    /* VGA signals */
    output wire                             v_sync_out,             // vertical sync pulse
    output wire                             h_sync_out,             // horizontal sync pulse
    output wire [3 : 0]                     gray_out,               // the gray scale pixel value

    /* QSPI signals */
    output reg  [3 : 0]                     data_dir,
    input  wire [3 : 0]                     data_in,
    output reg  [3 : 0]                     data_out,
    output reg                              chip_enable,

    /* Write signals */
    input wire                              write_mode,
    input wire  [3 : 0]                     write_data_in,
    input wire                              reset_write_ptr,
    input wire                              write_data,
    output reg                              wrote_data
);
    localparam  PIXEL_DIV       = 2;

    /* Calculate some helpfull constants */
    parameter WIDTH_PIXEL_CTR   = $clog2(LINE_VISIBLE + LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH);
    parameter WIDTH_LINE_CTR    = $clog2(ROW_VISIBLE + ROW_FRONT_PORCH + ROW_SYNC_PULSE + ROW_BACK_PORCH);

    assign v_sync_out           = v_sync;
    assign h_sync_out           = h_sync;

    /* Counter and state machine for pixels in a line */
    reg  [WIDTH_PIXEL_CTR - 1 : 0]  pixel_ctr;
    reg                             h_sync;
    reg                             new_line;
    reg                             row_reset;
    always @(posedge clk) begin
        if (rst_n == 0) begin
            pixel_ctr                       <= 0;
            row_reset                       <= 1;
            h_sync                          <= 0;
        end else begin
            new_line                        <= 0;
            pixel_ctr                       <= pixel_ctr + 1;

            if (pixel_ctr == LINE_VISIBLE - 1) begin
                row_reset                   <= 1;
            end

            if (pixel_ctr == LINE_VISIBLE + LINE_FRONT_PORCH - 2) begin
                new_line                    <= 1;
            end

            if (pixel_ctr == LINE_VISIBLE + LINE_FRONT_PORCH - 1) begin
                h_sync                      <= 1;
            end

            if (pixel_ctr == LINE_VISIBLE + LINE_FRONT_PORCH + LINE_SYNC_PULSE - 1) begin
                h_sync                      <= 0;
            end

            if (pixel_ctr == LINE_VISIBLE + LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH - 1) begin
                row_reset                   <= 0;
                pixel_ctr                   <= 0;
            end
        end
    end

    /* Counter and state machine for lines in a frame */
    reg  [WIDTH_LINE_CTR - 1 : 0]   line_ctr;
    reg                             v_sync;
    reg                             line_reset;
    always @(posedge clk) begin
        if (rst_n == 0) begin
            line_ctr                        <= 0;
            line_reset                      <= 1;
            v_sync                          <= 0;
        end else begin
            if (new_line == 1) begin
                line_ctr                        <= line_ctr + 1;

                if (line_ctr == ROW_VISIBLE - 1) begin
                    line_reset                  <= 1;
                end

                if (line_ctr == ROW_VISIBLE + ROW_FRONT_PORCH - 1) begin
                    v_sync                      <= 1;
                end

                if (line_ctr == ROW_VISIBLE + ROW_FRONT_PORCH + ROW_SYNC_PULSE - 1) begin
                    v_sync                      <= 0;
                end

                if (line_ctr == ROW_VISIBLE + ROW_FRONT_PORCH + ROW_SYNC_PULSE + ROW_BACK_PORCH - 1) begin
                    line_reset                  <= 0;
                    line_ctr                    <= 0;
                end
            end
        end
    end

    /* Black out the pixels while not in the visible area */
    assign  gray_out = (row_reset == 1 || line_reset == 1) ? 0 : 4'b1111;

    /* Statemachine for QSPI RAM */
    reg [4 : 0]     state;
    always @(posedge clk) begin
        if (rst_n == 0) begin
            state                   <= 0;
            chip_enable             <= 1'b1;
        end else begin
            case (state)
                // Reset enable
                0:
                    chip_enable     <= 1'b0;
                    data_dir        <= 4'b0001;
                    state           <= 1;
                1: 
                    data_out[0]     <= 0;
                    state           <= 2;
                2: 
                    data_out[0]     <= 1;
                    state           <= 3;
                3: 
                    data_out[0]     <= 1;
                    state           <= 4;
                4: 
                    data_out[0]     <= 0;
                    state           <= 5;
                5: 
                    data_out[0]     <= 0;
                    state           <= 6;
                6: 
                    data_out[0]     <= 1;
                    state           <= 7;
                7: 
                    data_out[0]     <= 1;
                    state           <= 8;
                8: 
                    data_out[0]     <= 0;
                    state           <= 9;
                9:
                    chip_enable     <= 1'b1;
                    state           <= 10;
                10:
                    state           <= 11;

                // Reset
                11:
                    chip_enable     <= 1'b0;
                    state           <= 12;
                12: 
                    data_out[0]     <= 0;
                    state           <= 13;
                13: 
                    data_out[0]     <= 1;
                    state           <= 14;
                14: 
                    data_out[0]     <= 1;
                    state           <= 15;
                15: 
                    data_out[0]     <= 0;
                    state           <= 16;
                16: 
                    data_out[0]     <= 0;
                    state           <= 17;
                17: 
                    data_out[0]     <= 1;
                    state           <= 18;
                18: 
                    data_out[0]     <= 1;
                    state           <= 19;
                19: 
                    data_out[0]     <= 0;
                    state           <= 20;
                20:
                    chip_enable     <= 1'b1;
                    state           <= 21;
                21:
                    state           <= 22;

                22:
                    state           <= 22;

                default:
                    state           <= 0; 
            endcase
        end
    end
endmodule
