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
    parameter CTRWIDTH      = 7,
    parameter HEIGHT        = 240,
    parameter WIDTH         = 320
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     run,
    output wire                     running,
    input  wire [CTRWIDTH - 1 : 0]  max_ctr,
    input  wire [2 : 0]             ctr_select,
    input  wire [6 : 0]             scaling,
    input  wire [BITWIDTH - 1 : 0]  cr_offset,
    input  wire [BITWIDTH - 1 : 0]  ci_offset,
    output reg  [3 : 0]             ctr_out,
    output reg                      finished
);
    localparam BITWIDTH_WIDTH   = $clog2(WIDTH);
    localparam BITWIDTH_HEIGHT  = $clog2(HEIGHT);

    wire signed [BITWIDTH - 1 : 0]          in_cr;
    wire signed [BITWIDTH - 1 : 0]          in_ci;
    wire signed [BITWIDTH - 1 : 0]          in_zr;
    wire signed [BITWIDTH - 1 : 0]          in_zi;
    wire signed [BITWIDTH - 1 : 0]          out_zr;
    wire signed [BITWIDTH - 1 : 0]          out_zi;
    wire                                    size;
    wire                                    overflow;

    reg  signed [BITWIDTH - 1 : 0]          cr;
    reg  signed [BITWIDTH - 1 : 0]          ci;
    reg  signed [BITWIDTH - 1 : 0]          zr;
    reg  signed [BITWIDTH - 1 : 0]          zi;
    reg         [CTRWIDTH - 1 : 0]          ctr;
    reg                                     stopped;
    reg                                     overflowed;

    reg         [BITWIDTH_WIDTH - 1 : 0]    x;
    reg         [BITWIDTH_HEIGHT - 1 : 0]   y;

    reg                                     l_alu_finished;

    wire                                    alu_finished;
    wire                                    alu_start;

    assign alu_start                    = (stopped == 1'b1) ? run : l_alu_finished;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            finished                    <= 1'b1;
            stopped                     <= 1'b1;
            l_alu_finished              <= 1'b0;
        end else begin
            l_alu_finished              <= alu_finished;
            if (stopped == 1'b0) begin
                if (l_alu_finished == 1'b1) begin            
                    if (size == 1'b1 || ctr == max_ctr || overflowed) begin
                        ctr                 <= 0;
                        overflowed          <= 0;
                        case (ctr_select)
                            3'b000: ctr_out  <= ctr[3 : 0];
                            3'b001: ctr_out  <= ctr[4 : 1];
                            3'b010: ctr_out  <= ctr[5 : 2];
                            3'b011: ctr_out  <= ctr[6 : 3];
                            3'b100: ctr_out  <= ctr[7 : 4];
                            3'b101: ctr_out  <= ctr[8 : 5];
                            3'b110: ctr_out  <= ctr[9 : 6];
                            3'b111: ctr_out  <= {ctr[9], ctr[6], ctr[3], ctr[0]};
                        endcase

                        zr                  <= 0;
                        zi                  <= 0;
                        stopped             <= 1'b1;

                        if (x == WIDTH - 1) begin
                            cr              <= cr_offset;
                            ci              <= ci + {{(BITWIDTH - 7){1'b0}}, scaling} + 1;

                            x               <= 0;
                            y               <= y + 1;
                            if (y == HEIGHT - 1) begin
                                finished    <= 1'b1;
                            end
                        end else begin
                            cr              <= cr + {{(BITWIDTH - 7){1'b0}}, scaling} + 1;
                            x               <= x + 1;
                        end
                    end else begin
                        zr                  <= out_zr;
                        zi                  <= out_zi;
                        ctr                 <= ctr + 1;
                        overflowed          <= overflow;
                    end
                end
            end else begin
                if (run == 1'b1) begin
                    finished            <= 1'b0;
                    stopped             <= 1'b0;
                end

                if (finished == 1'b1) begin
                    cr                 <= cr_offset;
                    ci                 <= ci_offset;
                    zr                 <= 0;
                    zi                 <= 0;
                    ctr                <= 0;
                    overflowed         <= 0;
                    x                  <= 0;
                    y                  <= 0;
                end
            end
        end      
    end

    assign in_cr = cr;
    assign in_ci = ci;

    assign in_zr = zr;
    assign in_zi = zi;

    assign running = ~stopped;

    mandelbrot_alu #(.WIDTH(BITWIDTH)) alu (
        .clk(clk),
        .rst_n(rst_n),
        .start(alu_start),
        .finished(alu_finished),
        .in_cr(in_cr),
        .in_ci(in_ci),
        .in_zr(in_zr),
        .in_zi(in_zi),
        .out_zr(out_zr),
        .out_zi(out_zi),
        .size(size),
        .overflow(overflow)
    );
endmodule
