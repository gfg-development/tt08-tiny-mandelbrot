/* This is a simple serial multiplier for signed numbers.
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
 * File     : bit_serial_mult.v
 * Create   : Aug 15, 2024
 * Revise   : Aug 15, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */
 `default_nettype none


module bit_serial_mult #( parameter WIDTH = 8) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [WIDTH - 1 : 0]     in_x,
    input  wire [WIDTH - 1 : 0]     in_y,
    input  wire                     start,
    output wire [2 * WIDTH - 1 : 0] out,
    output wire                     finished
);
    parameter WIDTH_CTR                 = $clog2(WIDTH);
    reg                         running;
    reg  [WIDTH_CTR - 1 : 0]    ctr;  
    reg  [2 * WIDTH - 1 : 0]    shift_reg;

    
    wire  [WIDTH : 0]           inverted_y;
    wire  [WIDTH : 0]           y;
    wire  [WIDTH : 0]           adder_result;
    wire  [WIDTH : 0]           shift_input;

    assign inverted_y   = ~{in_y[WIDTH - 1], in_y} + 1;

    assign y            = (ctr == WIDTH - 1) ? inverted_y : {in_y[WIDTH - 1], in_y};
    assign adder_result = y + {shift_reg[2 * WIDTH - 1], shift_reg[2 * WIDTH - 1 : WIDTH]};
    assign shift_input  = (shift_reg[0] == 1'b1) ? adder_result : {shift_reg[2 * WIDTH - 1], shift_reg[2 * WIDTH - 1 : WIDTH]};

    always @ (posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            running                             <= 1'b0;
        end else begin
            if (running) begin
                shift_reg                       <= {shift_input, shift_reg[WIDTH - 1 : 1]};
                ctr                             <= ctr + 1;
                
                if (ctr == WIDTH - 1) begin
                   running                      <= 1'b0; 
                end
            end else begin
                if (start) begin
                    shift_reg                   <= {{WIDTH{1'b0}}, in_x};
                    running                     <= 1'b1;
                    ctr                         <= 0;
                end
            end
        end
    end

    assign out = shift_reg;
    assign finished = !running;

endmodule
