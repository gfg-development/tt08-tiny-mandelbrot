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
    input  wire         write_mode,
    input  wire         ptr_reset,
    input  wire         doit
 );
    reg [3 : 0]         ram [76799 : 0];
    reg [16 : 0]        read_ptr;
    reg [16 : 0]        write_ptr;
    reg [3 : 0]         output_buffer;
    reg [3 : 0]         ram_output;

    always @(posedge clk) begin
        output_buffer               <= ram[read_ptr];

        if (ptr_reset == 1'b1) begin
            if (write_mode == 1'b1) begin
                write_ptr           <= 0;
            end else begin
                read_ptr            <= 0;
            end
        end else begin
            if (doit == 1'b1) begin
                if (write_mode == 1'b1) begin
                    write_ptr       <= write_ptr + 1;
                    ram[write_ptr]  <= in;
                end else begin
                    read_ptr        <= read_ptr + 1;
                end 
            end
        end
    end

    assign out = output_buffer;    
 endmodule