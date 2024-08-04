/* A simple implementation of the external framebuffer.
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (c) 2024 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 * SPDX-License-Identifier: Apache-2.0
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : framebuffer.v
 * Create   : Jul 30, 2024
 * Revise   : Jul 30, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */

 `default_nettype none

 module framebuffer #(
    parameter DELAY = 625000
 ) (
    input  wire         clk,
    input  wire [3 : 0] in,
    output wire [3 : 0] out,
    input  wire         read,
    input  wire         reset_read_ptr,
    input  wire         write,
    input  wire         reset_write_ptr
 );
    reg [3 : 0]         ram [76799 : 0];
    reg [16 : 0]        read_ptr;
    reg [16 : 0]        write_ptr;
    reg [3 : 0]         output_buffer;
    reg [3 : 0]         ram_output;

    always @(posedge clk) begin
        output_buffer               <= ram[read_ptr];

        if (write == 1'b1) begin
            write_ptr       <= write_ptr + 1;
            ram[write_ptr]  <= in;
        end

        if (read == 1'b1) begin
            read_ptr        <= read_ptr + 1;
        end;

        if (reset_read_ptr == 1'b1) begin
            read_ptr            <= 0;
        end;

        if (reset_write_ptr == 1'b1) begin
            write_ptr           <= 0;
        end;
    end

    assign out = output_buffer;    
 endmodule