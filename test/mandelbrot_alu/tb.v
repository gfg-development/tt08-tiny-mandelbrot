`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg [10:0]  in_cr;
  reg [10:0]  in_ci;
  reg [10:0]  in_zr;
  reg [10:0]  in_zi;
  reg         clk;

  wire [10:0] out_zr;
  wire [10:0] out_zi;
  wire        size;

  mandelbrot_alu #(.WIDTH(11)) alu (
        .in_cr(in_cr),
        .in_ci(in_ci),
        .in_zr(in_zr),
        .in_zi(in_zi),
        .out_zr(out_zr),
        .out_zi(out_zi),
        .size(size)
    );

  always @(posedge clk) begin
  end

endmodule
