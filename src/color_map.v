/* This is the color map for the Mandelbrot, from gray to RGB-222
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
 * File     : color_map.v
 * Create   : Aug 15, 2024
 * Revise   : Aug 15, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */
 `default_nettype none


module color_map (
    input  wire [3 : 0]     gray,
    output reg  [1 : 0]     R,
    output reg  [1 : 0]     G,
    output reg  [1 : 0]     B
);

    always @(gray) begin
        case (gray)
            4'h0:
                begin
                    R = 0;
                    G = 0;
                    B = 0;
                end

            4'h1:
                begin
                    R = 0;
                    G = 0;
                    B = 2;
                end

            4'h2:
                begin
                    R = 1;
                    G = 0;
                    B = 3;
                end

            4'h3:
                begin
                    R = 2;
                    G = 0;
                    B = 3;
                end

            4'h4:
                begin
                    R = 3;
                    G = 2;
                    B = 3;
                end

            4'h5:
                begin
                    R = 3;
                    G = 0;
                    B = 2;
                end


            4'h6:
                begin
                    R = 3;
                    G = 0;
                    B = 0;
                end

            4'h7:
                begin
                    R = 3;
                    G = 1;
                    B = 1;
                end

            4'h8:
                begin
                    R = 3;
                    G = 2;
                    B = 0;
                end

            4'h9:
                begin
                    R = 3;
                    G = 3;
                    B = 1;
                end

            4'hA:
                begin
                    R = 2;
                    G = 3;
                    B = 1;
                end

            4'hB:
                begin
                    R = 0;
                    G = 3;
                    B = 0;
                end

            4'hC:
                begin
                    R = 1;
                    G = 3;
                    B = 2;
                end

            4'hD:
                begin
                    R = 1;
                    G = 3;
                    B = 3;
                end

            4'hE:
                begin
                    R = 3;
                    G = 3;
                    B = 2;
                end

            4'hF:
                begin
                    R = 3;
                    G = 3;
                    B = 3;
                end
        endcase
    end
 
endmodule
