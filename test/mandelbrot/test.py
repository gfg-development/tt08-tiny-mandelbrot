# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

WIDTH = 640
HEIGHT = 480

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 50 ns (20 MHz)
    clock = Clock(dut.clk, 50, units="ns")
    cocotb.start_soon(clock.start())

    SCALING = 2
    CR_OFFSET = - (511) * SCALING
    CI_OFFSET = - (HEIGHT // 2) * SCALING

    # Reset
    dut._log.info("Reset")
    dut.reset.value = 1
    dut.run.value = 0
    dut.ctr_select.value = 0
    dut.max_ctr.value = 15
    dut.scaling.value = SCALING
    dut.cr_offset = CR_OFFSET
    dut.ci_offset = CI_OFFSET
    await ClockCycles(dut.clk, 10)
    dut.reset.value = 0

    await ClockCycles(dut.clk, 10)

    dut._log.info("Test project behavior")

    # Setting start flag
    dut.run.value = 1
    await ClockCycles(dut.clk, 1)
    dut.run.value = 0

    with open("image_{}_{}_{}.ppm".format(SCALING, CR_OFFSET, CI_OFFSET), "w+") as f:
        f.write("P2\r\n{} {}\r\n15\r\n".format(WIDTH, HEIGHT))
        for y in range(HEIGHT):
            print("Line: {}".format(y))
            for _ in range(WIDTH):
                await RisingEdge(dut.clk)
                while dut.new_ctr.value == 0:
                    await RisingEdge(dut.clk)
                f.write("{} ".format(int(str(dut.ctr_out.value), 2)))
            f.write("\r\n")
    assert dut.running.value == 0
