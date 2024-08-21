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
    input  wire                            clk,
    input  wire                            rst_n,
    input  wire                            start,
    input  wire                            first_iteration,
    output wire                            finished,
    input  wire signed [WIDTH - 1 : 0]     in_cr,
    input  wire signed [WIDTH - 1 : 0]     in_ci,
    input  wire signed [WIDTH - 1 : 0]     in_zr,
    input  wire signed [WIDTH - 1 : 0]     in_zi,
    output wire signed [WIDTH - 1 : 0]     out_zr,
    output wire signed [WIDTH - 1 : 0]     out_zi,
    output wire                            size,
    output wire                            overflow
);
    wire signed [2 * WIDTH - 1 : 0] m1;
    wire signed [2 * WIDTH - 1 : 0] m2;
    wire signed [2 * WIDTH - 1 : 0] m3;

    wire signed [2 * WIDTH     : 0] diff_m1_m2;

    wire signed [WIDTH + 2     : 0] t_zr;
    wire signed [WIDTH + 3     : 0] t_zi;

    wire        [2 * WIDTH     : 0] t_sum;
    wire                            overflow_r;
    wire                            overflow_i;

    wire signed [WIDTH - 1 : 0]     result_zr;
    wire signed [WIDTH - 1 : 0]     result_zi;

    wire signed [WIDTH - 1 : 0]     next_zr;
    wire signed [WIDTH - 1 : 0]     next_zi;

    assign next_zr = (first_iteration) ? 0 : result_zr;
    assign next_zi = (first_iteration) ? 0 : result_zi;

    radix4_serial_mult #(.WIDTH(WIDTH)) mult_zr_zr (
        .clk(clk),
        .rst_n(rst_n),
        .in_x(next_zr),
        .in_y(in_zr),
        .start(start),
        .out(m1),
        .finished(finished)
    );

    radix4_serial_mult #(.WIDTH(WIDTH)) mult_zi_zi (
        .clk(clk),
        .rst_n(rst_n),
        .in_x(next_zi),
        .in_y(in_zi),
        .start(start),
        .out(m2)
    );

    radix4_serial_mult #(.WIDTH(WIDTH)) mult_zr_zi (
        .clk(clk),
        .rst_n(rst_n),
        .in_x(next_zr),
        .in_y(in_zi),
        .start(start),
        .out(m3)
    );

    assign diff_m1_m2 = {m1[2 * WIDTH - 1], m1} - {m2[2 * WIDTH - 1], m2};

    assign t_zr = diff_m1_m2[2 * WIDTH : WIDTH - 2] + {{3{in_cr[WIDTH - 1]}}, in_cr};
    assign t_zi = {m3[2 * WIDTH - 1], m3[2 * WIDTH - 1 : WIDTH - 3]} + {{4{in_ci[WIDTH - 1]}}, in_ci};

    assign result_zr    = t_zr[WIDTH - 1 : 0];
    assign result_zi    = t_zi[WIDTH - 1 : 0];

    assign out_zr       = result_zr;
    assign out_zi       = result_zi;

    assign t_sum = {1'b0, m1[2 * WIDTH - 1 : 0]} + {1'b0, m2[2 * WIDTH - 1 : 0]};

    assign size         = (t_sum[2 * WIDTH : WIDTH - 2] > (4 << (WIDTH - 2))) ? 1'b1 : 1'b0;

    assign overflow_r   = (t_zr[WIDTH + 2] == 1'b1) ? !(&t_zr[WIDTH + 2 : WIDTH - 1]) : |t_zr[WIDTH + 2 : WIDTH - 1];
    assign overflow_i   = (t_zi[WIDTH + 3] == 1'b1) ? !(&t_zi[WIDTH + 3 : WIDTH - 1]) : |t_zi[WIDTH + 3 : WIDTH - 1]; 
    assign overflow     = overflow_r | overflow_i;
endmodule
