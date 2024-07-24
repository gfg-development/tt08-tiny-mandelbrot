/* This is a simple component, that does one calculation step of the Mandelbrot.
 * It assumes that the input format is 2.(WIDHT-2).
 * Furthermore, the internal results of the multiplication and additons have the 
 * format 3.(WIDTH-1).
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
 * File     : mandelbrot_alu.v
 * Create   : Jul 24, 2024
 * Revise   : Jul 24, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */
 `default_nettype none


module mandelbrot_alu #( parameter WIDTH = 8) (
    input  wire signed [WIDTH - 1 : 0]     in_cr,
    input  wire signed [WIDTH - 1 : 0]     in_ci,
    input  wire signed [WIDTH - 1 : 0]     in_zr,
    input  wire signed [WIDTH - 1 : 0]     in_zi,
    output wire signed [WIDTH - 1 : 0]     out_zr,
    output wire signed [WIDTH - 1 : 0]     out_zi,
    output wire                            size
);
    wire signed [2 * WIDTH - 1 : 0] m1;
    wire signed [2 * WIDTH - 1 : 0] m2;
    wire signed [2 * WIDTH - 1 : 0] m3;

    wire signed [WIDTH + 1 : 0]     t_zr;
    wire signed [WIDTH + 1 : 0]     t_zi;

    wire        [WIDTH + 1 : 0]     t_sum;

    assign m1       = in_zr * in_zr;
    assign m2       = in_zi * in_zi;
    assign m3       = in_zr * in_zi;
    
    assign t_zr     = m1[2 * WIDTH - 3 : WIDTH - 3] - m2[2 * WIDTH - 3 : WIDTH - 3] + {{1{in_cr[WIDTH - 1]}}, in_cr, 1'b0};
    assign t_zi     = m3[2 * WIDTH - 2 : WIDTH - 2] + {{1{in_ci[WIDTH - 1]}}, in_ci,  1'b0};

    assign out_zr   = t_zr[WIDTH : 1];
    assign out_zi   = t_zi[WIDTH : 1];

    assign t_sum    = m1[2 * WIDTH - 3 : WIDTH - 3] + m2[2 * WIDTH - 3 : WIDTH - 3];
    assign size     = (t_sum[WIDTH + 1 : WIDTH - 2] > 4) ? 1'b1 : 1'b0;
endmodule
