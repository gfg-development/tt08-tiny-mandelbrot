`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();
  // Wire up the inputs and outputs:
  reg clk;
  reg reset;
  reg run;
  reg [1:0]   ctr_select;
  reg [6:0]   max_ctr;
  reg [1:0]   scaling;
  reg [10:0]  cr_offset;
  reg [10:0]  ci_offset;

  wire [3:0] ctr_out;
  wire       new_ctr;
  wire       running;

  mandelbrot #(.BITWIDTH(11), .CTRWIDTH(7)) mandelbrot (
      .clk(clk),
      .reset(reset),
      .run(run),
      .running(running),
      .max_ctr(max_ctr),
      .ctr_select(ctr_select),
      .scaling(scaling),
      .cr_offset(cr_offset),
      .ci_offset(ci_offset),
      .ctr_out(ctr_out),
      .new_ctr(new_ctr)
  );

endmodule
