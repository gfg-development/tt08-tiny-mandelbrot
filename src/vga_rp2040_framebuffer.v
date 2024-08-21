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

module vga_rp2040_framebuffer #(
    parameter LINE_VISIBLE      = 640,
    parameter LINE_FRONT_PORCH  = 16,
    parameter LINE_SYNC_PULSE   = 96,
    parameter LINE_BACK_PORCH   = 48,

    parameter ROW_VISIBLE       = 480,
    parameter ROW_FRONT_PORCH   = 10,
    parameter ROW_SYNC_PULSE    = 2,
    parameter ROW_BACK_PORCH    = 33,

    parameter SYNC_POLARITY     = 0
) (
    /* General signals */
    input  wire                             clk,                    // clock
    input  wire                             rst_n,                  // low active reset, already synchronized to the clock

    /* VGA signals */
    output wire                             v_sync_out,             // vertical sync pulse
    output wire                             h_sync_out,             // horizontal sync pulse
    output wire [3 : 0]                     gray_out,               // the gray scale pixel value

    /* Databus signals */
    input  wire [3 : 0]                     data_in,
    output wire [7 : 0]                     ctrl_data_out,

    /* Write signals */
    input wire  [3 : 0]                     write_data_in,
    input wire                              reset_write_ptr,
    input wire                              write_data,
    output reg                              wrote_data
);
    localparam WIDTH_PIXEL_CTR = $clog2(LINE_VISIBLE + LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH);

    wire                            h_sync;
    wire                            h_blank;
    wire                            h_next;

    wire                            v_sync;
    wire                            v_blank;
    wire                            v_next;

    wire [WIDTH_PIXEL_CTR - 1 : 0]  pixel_ctr;

    assign v_sync_out           = (SYNC_POLARITY == 0) ? !v_sync : v_sync;
    assign h_sync_out           = (SYNC_POLARITY == 0) ? !h_sync : h_sync;

    vga_timing #(
        .VISIBLE(LINE_VISIBLE),
        .FRONT_PORCH(LINE_FRONT_PORCH),
        .SYNC_PULSE(LINE_SYNC_PULSE),
        .BACK_PORCH(LINE_BACK_PORCH),
        .WIDTH(WIDTH_PIXEL_CTR)
    ) timing_h (
        .clk(clk),
        .rst_n(rst_n),
        .enable(1'b1),
        .sync(h_sync),
        .next(h_next),
        .blank(h_blank),
        .pixel(pixel_ctr)
    );

    vga_timing #(
        .VISIBLE(ROW_VISIBLE),
        .FRONT_PORCH(ROW_FRONT_PORCH),
        .SYNC_PULSE(ROW_SYNC_PULSE),
        .BACK_PORCH(ROW_BACK_PORCH),
        .WIDTH($clog2(ROW_VISIBLE + ROW_FRONT_PORCH + ROW_SYNC_PULSE + ROW_BACK_PORCH))
    ) timing_v (
        .clk(clk),
        .rst_n(rst_n),
        .enable(h_next),
        .sync(v_sync),
        .blank(v_blank)
    );

    /* Black out the pixels while not in the visible area */
    assign  gray_out = (h_blank == 1'b1 || v_blank == 1'b1) ? 0 : pixel_buffer;

    /* Handling the frame buffer */
    reg                             l_read;
    reg [3 : 0]                     pixel_buffer;

    wire                            read;
    wire                            reset_read_ptr;

    wire [WIDTH_PIXEL_CTR - 1 : 0]  before_pixel_ctr;

    assign before_pixel_ctr = pixel_ctr - (LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH - 3);

    assign read = (before_pixel_ctr < LINE_VISIBLE) ? (before_pixel_ctr[0]) && !v_blank : 1'b0; // (!pixel_ctr[0] && ((pixel_ctr[WIDTH_PIXEL_CTR - 1 : 1] < LINE_VISIBLE / 2 - 1) || (pixel_ctr[WIDTH_PIXEL_CTR - 1 : 1] == (LINE_VISIBLE + LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH) / 2 - 1))) && !v_blank;

    always @(posedge clk) begin
        wrote_data                      <= write_data;

        l_read                          <= read;
        if (l_read ==  1'b1) begin
           pixel_buffer                 <= data_in[3 : 0];
        end       
    end

    assign reset_read_ptr   = v_sync;
    assign ctrl_data_out    = {read, reset_read_ptr, write_data, reset_write_ptr, write_data_in};
endmodule
