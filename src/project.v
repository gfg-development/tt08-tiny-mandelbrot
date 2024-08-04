/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_gfg_development_tinymandelbrot (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, 1'b0};

    wire reset;
    assign reset = !rst_n;

    // output_select == 1 --> use binary interface, 0 --> VGA interface
    wire output_select;
    assign output_select    = ui_in[3];

    // Multiplexing IOs between the different modes
    assign uo_out[0]  = (output_select == 1'b1) ? ctr_out[0]  : R[1];
    assign uo_out[1]  = (output_select == 1'b1) ? ctr_out[1]  : G[1];
    assign uo_out[2]  = (output_select == 1'b1) ? ctr_out[2]  : B[1];
    assign uo_out[3]  = (output_select == 1'b1) ? ctr_out[3]  : vsync;
    assign uo_out[4]  = (output_select == 1'b1) ? running     : R[0];
    assign uo_out[5]  = (output_select == 1'b1) ? finished    : G[0];
    assign uo_out[6]  = (output_select == 1'b1) ? 1'b0        : B[0];
    assign uo_out[7]  = (output_select == 1'b1) ? 1'b0        : hsync;

    // shift register for controlling the system from the RP2040
    reg [32 : 0]  configuration;
    reg [2 : 0]   l_sdata;
    reg [2 : 0]   l_sclk;
    reg [2 : 0]   l_sen;
    always @(posedge clk) begin
        l_sdata <= {l_sdata[1 : 0], ui_in[1]};
        l_sclk  <= {l_sclk[1 : 0], ui_in[2]};
        l_sen   <= {l_sen[1 : 0], ui_in[0]};

        if (l_sen[2] == 1'b1 && l_sclk[2] == 1'b0 && l_sclk[1] == 1'b1) begin
            configuration   <= {l_sdata[2], configuration[32 : 1]};
        end
    end

    // The mandelbrot engine
    wire [3 : 0]  ctr_out;
    wire          running;
    wire          finished;
    reg           run_pixel;
    mandelbrot #(.BITWIDTH(11), .CTRWIDTH(7)) mandelbrot (
        .clk(clk),
        .reset(reset),
        .run(run_pixel),
        .running(running),
        .max_ctr(configuration[32 : 26]),
        .scaling(configuration[23 : 22]),
        .cr_offset(configuration[10 : 0]),
        .ci_offset(configuration[21 : 11]),
        .ctr_select(configuration[25 : 24]),
        .ctr_out(ctr_out),
        .finished(finished)
    );

    reg l_running;
    always @(posedge clk) begin
        l_running       <= running;
    end
    wire valid_data;
    assign valid_data   = (running == 1'b0 && l_running == 1'b1);


    // The VGA module
    wire [1 : 0]  R;
    wire [1 : 0]  G;
    wire [1 : 0]  B;
    wire [3 : 0]  gray;
    wire          hsync;
    wire          vsync;

    wire          wrote_data;

    assign R = gray[3 : 2];
    assign G = gray[2 : 1];
    assign B = gray[1 : 0];

    assign uio_oe = 8'hFF;

    vga_rp2040_framebuffer vga (
        .clk(clk),
        .rst_n(rst_n),

        .v_sync_out(vsync),
        .h_sync_out(hsync),
        .gray_out(gray),

        .ctrl_data_out(uio_out),
        .data_in(ui_in[7 : 4]),

        .write_data_in(ctr_out),
        .reset_write_ptr(reset_write_ptr),
        .write_data(valid_data),
        .wrote_data(wrote_data)
    );

    // The statemachine
    reg  [1 : 0]    state;
    reg             reset_write_ptr;

    always @(posedge clk) begin
        reset_write_ptr                     <= 1'b0;
        run_pixel                           <= 1'b0;
        if (reset == 1'b1) begin
            state                           <= 0;
        end else begin
            case (state)
                // Wait for start of rendering
                0:
                    begin
                        if (l_sen[2] == 1'b1 && l_sen[1] == 1'b0) begin
                            state           <= 1;
                        end
                    end

                // Reset the write pointer
                1: 
                    begin
                        reset_write_ptr     <= 1'b1;
                        run_pixel           <= 1'b1;
                        state               <= 2;
                    end

                // Wait for framebuffer to be ready to write next pixel
                2: 
                    begin
                        if (wrote_data == 1'b1) begin
                            run_pixel       <= 1'b1;
                            state           <= 3;
                        end
                    end

                // Write next pixel
                3:
                    begin
                        if (valid_data == 1'b1) begin
                            if (finished == 1'b1) begin
                                state       <= 0;
                            end else begin
                                state       <= 2;
                            end 
                        end
                    end

                default: 
                    state   <= 0;
            endcase
        end
    end
endmodule
