# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 15
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 10)

    dut._log.info("Test project behavior")

    assert dut.user_project.mandelbrot.running.value == 0

    # Setting start flag
    dut.ui_in.value = 128
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0

    with open("image.ppm", "w+") as f:
        f.write("P2\r\n640 480\r\n15\r\n")
        for y in range(480):
            print("Line: {}".format(y))
            for _ in range(640):
                await RisingEdge(dut.user_project.mandelbrot.new_ctr)
                await ClockCycles(dut.clk, 1)
                f.write("{} ".format(int(str(dut.user_project.mandelbrot.ctr_out.value), 2)))
            f.write("\r\n")
    assert dut.user_project.mandelbrot.running.value == 0
