/* This is the statemachine to calculate the Mandelbrot.
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (C) 2024 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : mandelbrot.v
 * Create   : Jul 24, 2024
 * Revise   : Jul 24, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */
 `default_nettype none


module mandelbrot #( 
    parameter BITWIDTH      = 10,
    parameter CTRWIDTH      = 4,
    parameter HEIGHT        = 480,
    parameter WIDTH         = 640
) (
    input  wire                     clk,
    input  wire                     reset,
    output reg  [CTRWIDTH - 1 : 0]  ctr_out,
    output reg                      new_ctr
);
    wire signed [BITWIDTH - 1 : 0]      in_cr;
    wire signed [BITWIDTH - 1 : 0]      in_ci;
    wire signed [BITWIDTH - 1 : 0]      in_zr;
    wire signed [BITWIDTH - 1 : 0]      in_zi;
    wire signed [BITWIDTH - 1 : 0]      out_zr;
    wire signed [BITWIDTH - 1 : 0]      out_zi;
    wire                                size;

    reg  signed [BITWIDTH - 1 : 0]      cr;
    reg  signed [BITWIDTH - 1 : 0]      ci;
    reg  signed [BITWIDTH - 1 : 0]      zr;
    reg  signed [BITWIDTH - 1 : 0]      zi;
    reg         [CTRWIDTH - 1 : 0]      ctr;

    always @(posedge clk) begin
        new_ctr             <= 1'b0;
        if (reset) begin
            cr              <= - HEIGHT / 2 - HEIGHT / 4 - HEIGHT / 8;
            ci              <= - HEIGHT / 2;
            zr              <= 0;
            zi              <= 0;
            ctr             <= 0;
        end else begin
            if (size == 1'b0 || ctr == 15) begin
                new_ctr     <= 1'b1;
                ctr_out     <= ctr;

                zr          <= 0;
                zi          <= 0;
                cr          <= cr + 1;
                ci          <= ci + 1;
            end else begin
                zr          <= out_zr;
                zi          <= out_zi;
                ctr         <= ctr + 1;
            end
        end
    end

    assign in_cr = cr;
    assign in_ci = ci;

    assign in_zr = zr;
    assign in_zi = zi;

    mandelbrot_alu #(.WIDTH(BITWIDTH)) alu (
        .in_cr(in_cr),
        .in_ci(in_ci),
        .in_zr(in_zr),
        .in_zi(in_zi),
        .out_zr(out_zr),
        .out_zi(out_zi),
        .size(size)
    );
endmodule
