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
  reg [1:0] ctr_select;
  reg [6:0] max_ctr;

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
      .ctr_out(ctr_out),
      .new_ctr(new_ctr)
  );

endmodule
