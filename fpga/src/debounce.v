/* A simple debouncer for buttons and switches.
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (c) 2024 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 * SPDX-License-Identifier: Apache-2.0
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : debounce.v
 * Create   : Jul 30, 2024
 * Revise   : Jul 30, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */

 `default_nettype none

 module debounce #(
    parameter DELAY = 125000
 ) (
    input  wire      clk,
    input  wire      in,
    output wire      out
 );
    reg [31 : 0]        counter;
    reg                 state;

    always @(posedge clk) begin
        if (state != in) begin
            counter     <= counter + 1;
        end else begin
            counter     <= 0;
        end

        if (counter == DELAY - 1) begin
            state       <= in;
        end
    end

    assign out = state;    
 endmodule