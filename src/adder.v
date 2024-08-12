/* This is a simple adder based on a ripple-carry adder.
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
 * File     : adder.v
 * Create   : Aug 12, 2024
 * Revise   : Aug 12, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */
`default_nettype none

module adder #( parameter WIDTH = 8 ) (
    input  wire [WIDTH - 1 : 0] ina,
    input  wire [WIDTH - 1 : 0] inb,
    output wire [WIDTH : 0]     out
);

    wire [WIDTH - 1 : 0]    carries;
    wire [WIDTH - 1 : 0]    sum;

    sky130_fd_sc_hd__ha_1 ha (
        .A(ina[0]), 
        .B(inb[0]), 
        .COUT(carries[0]), 
        .SUM(sum[0])
    );

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            sky130_fd_sc_hd__fa_1 fa (
                .A(ina[i]), 
                .B(inb[i]), 
                .CIN(carries[i - 1]), 
                .COUT(carries[i]), 
                .SUM(sum[i])
            );
        end
    endgenerate

    assign out      = {carries[WIDTH - 1], sum};

endmodule