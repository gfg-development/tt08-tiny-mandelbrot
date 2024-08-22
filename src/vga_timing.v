/* The timing generator for the VGA pixels.
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (c) 2024 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 * SPDX-License-Identifier: Apache-2.0
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : vga_timing.v
 * Create   : Aug 20, 2024
 * Revise   : Aug 20, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */

`default_nettype none

module vga_timing #(
    parameter VISIBLE      = 640,
    parameter FRONT_PORCH  = 16,
    parameter SYNC_PULSE   = 96,
    parameter BACK_PORCH   = 48,
    parameter WIDTH        = 9
) (
    /* General signals */
    input  wire                             clk,                    // clock
    input  wire                             rst_n,                  // low active reset, already synchronized to the clock
    input  wire                             enable,


    /* VGA signals */
    output wire                             sync,
    output wire                             next,          
    output wire                             blank,
    output wire [WIDTH - 1 : 0]             pixel
);
    /* Counter and state machine for pixels in a line */
    reg  [WIDTH - 1 : 0]            pixel_ctr;
    wire                            next_int;
    

    assign sync     = ((pixel_ctr >= FRONT_PORCH) && (pixel_ctr < FRONT_PORCH + SYNC_PULSE)) ? 1'b1 : 1'b0;
    assign next_int = ((pixel_ctr >= FRONT_PORCH + SYNC_PULSE + BACK_PORCH + VISIBLE - 1) && enable) ? 1'b1 : 1'b0;
    assign blank    = (pixel_ctr >= FRONT_PORCH + SYNC_PULSE + BACK_PORCH) ? 1'b0 : 1'b1;

    assign next     = next_int;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_ctr                       <= 0;
        end else begin
            if (enable) begin
                if (next_int == 1'b1) begin
                    pixel_ctr               <= 0;
                end else begin
                    pixel_ctr               <= pixel_ctr + 1;
                end
            end             
        end
    end

    assign pixel = pixel_ctr;
 endmodule
 