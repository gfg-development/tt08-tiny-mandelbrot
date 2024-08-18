`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

    // Dump the signals to a VCD file. You can view it with gtkwave.
    /*initial begin
        $dumpfile("tb.vcd");
        $dumpvars; // (1, tb);
        #1;
    end*/

    // Wire up the inputs and outputs:
    reg clk;
    reg start;
    reg rst_n;
    reg [7:0] x;
    reg [7:0] y;
    wire [15:0] result;
    wire finished;

    // Replace tt_um_example with your module name:
    bit_serial_mult dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_x(x),
        .in_y(y),
        .start(start),
        .out(result),
        .finished(finished)
    );
endmodule
