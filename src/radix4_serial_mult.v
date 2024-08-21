/* This is a simple radix-4 booth multiplier for signed numbers.
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
 * File     : radix4_serial_mult.v
 * Create   : Aug 15, 2024
 * Revise   : Aug 15, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */
 `default_nettype none


module radix4_serial_mult #( parameter WIDTH = 8) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [WIDTH - 1 : 0]     in_x,
    input  wire [WIDTH - 1 : 0]     in_y,
    input  wire                     start,
    output wire [2 * WIDTH - 1 : 0] out,
    output wire                     finished
);
    parameter LOCAL_WIDTH               = (WIDTH + 1) / 2;
    parameter FULL_WIDTH                = 2 * LOCAL_WIDTH;
    parameter WIDTH_CTR                 = $clog2(LOCAL_WIDTH);

    wire  [2 * LOCAL_WIDTH - 1 : 0] int_x;
    wire  [2 * LOCAL_WIDTH - 1 : 0] int_y;

    generate
        if (FULL_WIDTH != WIDTH) begin : gen_sign_extion
            assign int_x        = {in_x[WIDTH - 1], in_x};
            assign int_y        = {in_y[WIDTH - 1], in_y};
        end else begin : gen_pass_through
            assign int_x        = in_x;
            assign int_y        = in_y;
        end
    endgenerate


    reg                             running;
    reg  [WIDTH_CTR - 1  : 0]       ctr;  
    reg  [2 * FULL_WIDTH : 0]       shift_reg;

    
    wire  [FULL_WIDTH : 0]          inverted_y;
    wire  [FULL_WIDTH : 0]          y;
    wire  [FULL_WIDTH + 1 : 0]      y_shifted;
    wire  [FULL_WIDTH + 1 : 0]      shift_to_adder;
    wire  [FULL_WIDTH + 1 : 0]      adder_result;
    wire  [FULL_WIDTH + 1 : 0]      shift_input;

    wire                            neg;
    wire                            double;

    assign neg              = shift_reg[2];
    assign double           = (neg == 1'b1) ? (shift_reg[1 : 0] == 2'b00) : (shift_reg[1 : 0] == 2'b11);

    assign inverted_y       = ~{int_y[FULL_WIDTH - 1], int_y} + 1;

    assign y                = (shift_reg[2] == 1'b1) ? inverted_y : {int_y[FULL_WIDTH - 1], int_y};
    assign y_shifted        = (double) ? {y, 1'b0} : {y[FULL_WIDTH], y};

    assign shift_to_adder   = {{2{shift_reg[2 * FULL_WIDTH]}}, shift_reg[2 * FULL_WIDTH : FULL_WIDTH + 1]};

    assign adder_result     = y_shifted + shift_to_adder;
    
    assign shift_input      = ((shift_reg[2 : 0] == 3'b111) || (shift_reg[2 : 0] == 3'b000)) ? {{2{shift_reg[2 * FULL_WIDTH]}}, shift_reg[2 * FULL_WIDTH : FULL_WIDTH + 1]} : adder_result;

    always @ (posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            running                             <= 1'b0;
        end else begin
            if (running) begin
                shift_reg                       <= {shift_input, shift_reg[FULL_WIDTH : 2]};
                ctr                             <= ctr + 1;
                
                if (ctr == LOCAL_WIDTH - 1) begin
                   running                      <= 1'b0; 
                end
            end else begin
                if (start) begin
                    shift_reg                   <= {{FULL_WIDTH{1'b0}}, int_x, 1'b0};
                    running                     <= 1'b1;
                    ctr                         <= 0;
                end
            end
        end
    end

    assign out = shift_reg[2 * WIDTH : 1];
    assign finished = ~running;

endmodule
