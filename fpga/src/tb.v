`timescale 1ns/1ns;
module tb_toplevel ();
    parameter PERIOD = 4;

    reg             clk;
    reg  [1 : 0]    btn;
    wire [3 : 0]    VGA_R;
    wire [3 : 0]    VGA_G;
    wire [3 : 0]    VGA_B;
    wire            VGA_HS;
    wire            VGA_VS;
    wire [0 : 0]    led;

    initial begin
    $display($time, " << Starting the Simulation >>");
        btn = 2'b01;
        clk = 0;
        wait (led == 1'b1) @(posedge clk);
        #2500;
        @(posedge clk);
        btn = 2'b00;
        #2500;
        @(posedge clk);
        btn = 2'b10;
        #2500;
        @(posedge clk);
        btn = 2'b00;
    end

    always #PERIOD clk=~clk;

    toplevel #(.DEBOUNCE(8)) toplevel (
        .sys_clk_pin(clk),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS_O(VGA_HS),
        .VGA_VS_O(VGA_VS),
        .btn(btn),
        .led(led)
    );
endmodule