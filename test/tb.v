`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  /*initial begin
    $dumpfile("tb.vcd");
    $dumpvars(2, tb);
    #1;
  end*/

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  wire          running;
  wire          finished;

  wire          vsync;
  wire          hsync;
  wire [1 : 0]  red;
  wire [1 : 0]  green;
  wire [1 : 0]  blue;

  wire          read;
  wire          reset_read_ptr;

  wire          write;
  wire          reset_write_ptr;
  wire [3 : 0]  write_data;

  assign running  = uo_out[4];
  assign finished = uo_out[5];

  assign vsync = uo_out[3];
  assign hsync = uo_out[7];

  assign red   = {uo_out[0], uo_out[4]};
  assign green = {uo_out[1], uo_out[5]};
  assign blue  = {uo_out[2], uo_out[6]};

  assign read             = uio_out[7];
  assign reset_read_ptr   = uio_out[6];

  assign write            = uio_out[5];
  assign reset_write_ptr  = uio_out[4];

  assign write_data       = uio_out[3 : 0];

  // Replace tt_um_example with your module name:
  tt_um_gfg_development_tinymandelbrot user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule
