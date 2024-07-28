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

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out        = 0;
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

  wire reset;
  assign reset = !rst_n;

  // output_select == 1 --> use binary interface, 0 --> VGA interface
  wire output_select;
  assign output_select    = ui_in[7];

  wire config_select;
  assign config_select    = ui_in[6];

  // Multiplexing IOs between the different modes
  assign uo_out[0]  = (output_select == 1'b1) ? ctr_out[0]  : R[1];
  assign uo_out[1]  = (output_select == 1'b1) ? ctr_out[1]  : G[1];
  assign uo_out[2]  = (output_select == 1'b1) ? ctr_out[2]  : B[1];
  assign uo_out[3]  = (output_select == 1'b1) ? ctr_out[3]  : vsync;
  assign uo_out[4]  = (output_select == 1'b1) ? running     : R[0];
  assign uo_out[5]  = (output_select == 1'b1) ? finished    : G[0];
  assign uo_out[6]  = (output_select == 1'b1) ? 1'b0        : B[0];
  assign uo_out[7]  = (output_select == 1'b1) ? 1'b0        : hsync;

  assign uio_oe     = (output_select == 1'b1) ? 8'b00000000 : 8'b00000000;

  // shift register for controlling the system from the RP2040
  reg [23 : 0]  configuration;
  always @(posedge clk) begin
    if (ui_in[4] == 1'b1) begin
      configuration   <= {configuration[22 : 0], ui_in[5]};
    end
  end

  // The mandelbrot engine
  wire [3 : 0]  ctr_out;
  wire          running;
  wire          finished;
  mandelbrot #(.BITWIDTH(11), .CTRWIDTH(7)) mandelbrot (
      .clk(clk),
      .reset(reset),
      .run(ui_in[0]),
      .running(running),
      .max_ctr(uio_in[6 : 0]),
      .scaling(configuration[23 : 22]),
      .cr_offset(configuration[10 : 0]),
      .ci_offset(configuration[21 : 11]),
      .ctr_select(ui_in[2 : 1]),
      .ctr_out(ctr_out),
      .finished(finished)
  );

  // The VGA module
  wire [1 : 0]  R;
  wire [1 : 0]  G;
  wire [1 : 0]  B;
  wire          hsync;
  wire          vsync;
endmodule
