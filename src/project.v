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
  assign uio_oe         = 0;
  assign uo_out[6 : 5]  = 0;
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};
  wire reset;

  reg [23 : 0]  configuration;

  reg [23 : 0]  test_sr1;
  reg [23 : 0]  test_sr2; 
  reg [23 : 0]  test_sr3; 
  reg [23 : 0]  test_sr4; 


  always @(posedge clk) begin
    if (ui_in[6] == 1'b1) begin
      configuration   <= {configuration[22 : 0], ui_in[7]};
      test_sr1        <= {test_sr1[22 : 0], ui_in[6]};
      test_sr2        <= {test_sr2[22 : 0], ui_in[5]};
      test_sr3        <= {test_sr3[22 : 0], ui_in[4]};
      test_sr4        <= {test_sr4[22 : 0], ui_in[3]};
    end
  end

  assign uo_out[5] = test_sr1[23] | test_sr2[23] | test_sr3[23] | test_sr4[23];

  assign reset = !rst_n;
  mandelbrot #(.BITWIDTH(11), .CTRWIDTH(7)) mandelbrot (
      .clk(clk),
      .reset(reset),
      .run(ui_in[7]),
      .running(uo_out[4]),
      .max_ctr(uio_in[6 : 0]),
      .scaling(configuration[23 : 22]),
      .cr_offset(configuration[10 : 0]),
      .ci_offset(configuration[21 : 11]),
      .ctr_select(ui_in[1 : 0]),
      .ctr_out(uo_out[3 : 0]),
      .new_ctr(uo_out[7])
  );

endmodule
