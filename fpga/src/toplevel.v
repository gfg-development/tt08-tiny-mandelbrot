/* The toplevel for the FPGA test.
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (c) 2024 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 * SPDX-License-Identifier: Apache-2.0
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : toplevel.v
 * Create   : Jul 30, 2024
 * Revise   : Jul 30, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */

`default_nettype none

module toplevel #(
    parameter DEBOUNCE = 125000
 ) (
    input  wire         sys_clk_pin,
    output wire [3 : 0] VGA_R,
    output wire [3 : 0] VGA_G,
    output wire [3 : 0] VGA_B,
    output wire         VGA_HS_O,
    output wire         VGA_VS_O,
    input  wire [1 : 0] btn,
    output wire [1 : 0] led
);
    wire [7 : 0]  ui_in;
    wire [7 : 0]  uo_out;
    wire [7 : 0]  uio_in;
    wire [7 : 0]  uio_out;
    wire [7 : 0]  uio_oe;
    wire          ena;
    wire          clk;
    wire          rst_n;

    tt_um_gfg_development_tinymandelbrot mandelbrot (
        .clk(clk),
        .ena(ena),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe)
    );

    assign VGA_R[2]     = uo_out[4]; 
    assign VGA_R[3]     = uo_out[0];
    assign VGA_R[1 : 0] = 0;

    assign VGA_G[2]     = uo_out[5]; 
    assign VGA_G[3]     = uo_out[1]; 
    assign VGA_G[1 : 0] = 0;

    assign VGA_B[2]     = uo_out[6]; 
    assign VGA_B[3]     = uo_out[2]; 
    assign VGA_B[1 : 0] = 0;

    assign VGA_VS_O = uo_out[3]; 
    assign VGA_HS_O = uo_out[7];

    framebuffer framebuffer (
        .clk(clk),
        .in(uio_out[3 : 0]),
        .out(ui_in[7 : 4]),
        .write(uio_out[5]),
        .read(uio_out[7]),
        .reset_read_ptr(uio_out[6]),
        .reset_write_ptr(uio_out[4])
    );

    clk_wiz_0 vga_clk (
        .clk_out1(clk),
        .locked(led[0]),
        .clk_in1(sys_clk_pin)
    );

    wire reset;
    assign rst_n    = ~reset;
    debounce #(.DELAY(DEBOUNCE)) deb_rst (
        .clk(clk),
        .in(btn[0]),
        .out(reset)
    );

    wire next;
    debounce #(.DELAY(DEBOUNCE)) deb_next (
        .clk(clk),
        .in(btn[1]),
        .out(next)
    );

    assign ui_in[3] = 1'b0;
    
    reg [2 : 0]     state               = 0;
    reg [5 : 0]     shift_ctr;
    reg [56 : 0]    configuration;
    reg [4  : 0]    configuration_ptr   = 0;
    reg             enable;
    reg             sclk;
    reg             l_next;
    always @(posedge clk) begin
        l_next                                      <= next;
        if (reset == 1'b1) begin
            state                                   <= 0;
            enable                                  <= 1'b0;
            sclk                                    <= 1'b0;
            configuration_ptr                       <= 0;
        end else begin
            case (state)
                0:
                    begin
                        if (next == 1'b1 && l_next == 1'b0) begin
                            case (configuration_ptr)
                                0:
                                    configuration           <= {15'h000F, 3'b000, 7'h7F, 16'hB500, 16'h6080};

                                1:
                                    configuration           <= {15'h003F, 3'b001, 7'h7F, 16'hB500, 16'h6080};

                                2:
                                    configuration           <= {15'h00FF, 3'b010, 7'h7F, 16'hB500, 16'h6080};

                                3:
                                    configuration           <= {15'h03FF, 3'b011, 7'h7F, 16'hB500, 16'h6080};

                                4:
                                    configuration           <= {15'h000F, 3'b000, 7'h7F, 16'hB500, 16'h6080};

                                5:
                                    configuration           <= {15'h003F, 3'b000, 7'h7F, 16'hB500, 16'h6080};

                                6:
                                    configuration           <= {15'h00FF, 3'b000, 7'h7F, 16'hB500, 16'h6080};

                                7:
                                    configuration           <= {15'h03FF, 3'b000, 7'h7F, 16'hB500, 16'h6080};

                                8:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h7F, 16'hBC40, 16'hF3CA};

                                9:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h3F, 16'hBC40, 16'hF3CA};

                                10:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h1F, 16'hBC40, 16'hF3CA};

                                11:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h0F, 16'hBC40, 16'hF3CA};

                                12:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h07, 16'hBC40, 16'hF3CA};

                                13:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h03, 16'hBC40, 16'hF3CA};

                                14:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h01, 16'hBC40, 16'hF3CA};

                                15:
                                    configuration           <= {15'h7FFF, 3'b110, 7'h00, 16'hBC40, 16'hF3CA};

                                16:
                                    configuration           <= {15'h7FFF, 3'b111, 7'h00, 16'hBC40, 16'hF3CA};

                                17:
                                    configuration           <= {15'h7FFF, 3'b111, 7'h01, 16'hBC40, 16'hF3CA};

                                default:
                                    begin
                                        configuration       <= {15'h000F, 3'b000, 7'h7F, 16'hB500, 16'h6080};
                                        configuration_ptr   <= 0;
                                    end
                            endcase

                            state                   <= 1;
                        end
                    end
                1:
                    begin
                        state                       <= 2;
                        enable                      <= 1'b0;
                        sclk                        <= 1'b0;
                        shift_ctr                   <= 0;
                    end 
                
                2:
                    begin
                        enable                      <= 1'b1;
                        state                       <= 3;
                    end

                3:
                    begin
                        sclk                        <= 1'b1;
                        state                       <= 4;
                    end 

                4:
                    begin
                        sclk                        <= 1'b0;
                        configuration               <= configuration >> 1;
                        
                        if (shift_ctr == 56) begin
                            state                   <= 5;
                            configuration_ptr       <= configuration_ptr + 1;
                        end else begin
                            shift_ctr               <= shift_ctr + 1;
                            state                   <= 3;
                        end 
                    end

                5:
                    begin
                        enable                      <= 1'b0;
                        state                       <= 0;
                    end 
                

                default:
                    begin
                        state                       <= state;
                    end 
            endcase
        end
    end

    assign led[1] = (state == 4) ? 1'b1 : 1'b0;

    assign ui_in[1] = configuration[0];
    assign ui_in[2] = sclk;
    assign ui_in[0] = enable;
endmodule