/* This is a simple adder based on a ripple-carry adder, which only outputs the
 * upper bits of the result.
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
 * File     : upper_adder.v
 * Create   : Aug 12, 2024
 * Revise   : Aug 12, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */
`default_nettype none

module upper_adder #( 
    parameter WIDTH         = 8,
    parameter RESULT_WIDTH  = 6
) (
    input  wire [WIDTH - 1 : 0]         ina,
    input  wire [WIDTH - 1 : 0]         inb,
    output wire [RESULT_WIDTH - 1 : 0]  out
);

    wire [WIDTH - 1 : 0]           carries;
    wire [RESULT_WIDTH - 1 : 0]    sum;

    assign carries[0] = ina[0] & inb[0];

    genvar j;
    generate
        for (j = 1; j < RESULT_WIDTH; j = j + 1) begin
            assign carries[i] = (carries[i - 1] & inb[i]) | ((carries[i - 1] | inb[i]) & (ina[i]));
        end
    endgenerate

    genvar i;
    generate
        for (i = RESULT_WIDTH; i < WIDTH; i = i + 1) begin
            sky130_fd_sc_hd__fa_1 fa (
                .A(ina[i]), 
                .B(inb[i]), 
                .CIN(carries[i - 1]), 
                .COUT(carries[i]), 
                .SUM(sum[RESULT_WIDTH - i])
            );
        end
    endgenerate

    assign out      = sum;

endmodule