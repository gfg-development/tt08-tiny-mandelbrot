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

module toplevel (
    input  wire         sys_clk_pin,
    output wire [4 : 1] ja_p,
    output wire [4 : 1] ja_n,
    input  wire [1 : 0] sw,
    input  wire [3 : 0] btn,
    output wire [0 : 0] led
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

    assign ja_p[1] = uo_out[0];
    assign ja_p[2] = uo_out[2]; 
    assign ja_p[3] = uo_out[4]; 
    assign ja_p[4] = uo_out[6]; 

    assign ja_n[1] = uo_out[1];
    assign ja_n[2] = uo_out[3]; 
    assign ja_n[3] = uo_out[5]; 
    assign ja_n[4] = uo_out[7];

    framebuffer framebuffer (
        .clk(clk),
        .in(uio_out[3 : 0]),
        .out(uio_in[3 : 0]),
        .write_mode(uio_out[7]),
        .ptr_reset(uio_out[6]),
        .doit(uio_out[5])
    );

    clk_wiz_0 vga_clk (
        .clk_out1(clk),
        .locked(led[0]),
        .clk_in1(sys_clk_pin)
    );

    wire reset;
    assign rst_n    = ~reset;
    debounce deb_rst (
        .clk(clk),
        .in(btn[0]),
        .out(reset)
    );

    wire render;
    debounce deb_render (
        .clk(clk),
        .in(btn[1]),
        .out(render)
    );
    assign ui_in[0] = render;
    
    reg [2 : 0]     state;
    reg [5 : 0]     shift_ctr;
    reg [32 : 0]    configuration;
    reg             enable;
    reg             sclk;
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            state                       <= 0;
            enable                      <= 1'b0;
            sclk                        <= 1'b0;
        end else begin
            case (state)
                0:
                    begin
                        configuration   <= 33'b0_0011_1100_0000_0000_0000_0000_0000_0000;
                        state           <= 1;
                        enable          <= 1'b0;
                        sclk            <= 1'b0;
                        shift_ctr       <= 0;
                    end 
                
                1:
                    begin
                        enable          <= 1'b1;
                        state           <= 2;
                    end

                2:
                    begin
                        sclk            <= 1'b1;
                        state           <= 3;
                    end 

                3:
                    begin
                        sclk            <= 1'b0;
                        configuration   <= configuration >> 1;
                        
                        if (shift_ctr == 32) begin
                            state       <= 4;
                        end else begin
                            shift_ctr   <= shift_ctr + 1;
                            state       <= 2;
                        end 
                    end

                4:
                    begin
                        state           <= 4;
                    end 
                

                default:
                    begin
                        state           <= 0;
                    end 
            endcase
        end
    end

    assign ui_in[5] = configuration[0];
    assign ui_in[6] = sclk;
    assign ui_in[4] = enable;
endmodule