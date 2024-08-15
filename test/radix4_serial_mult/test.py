# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge

async def run_case(dut, x, y):
    dut.x.value = x
    dut.y.value = y
    dut.start.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start.value = 0

    await ClockCycles(dut.clk, 9)
    assert dut.finished.value == 1
    if (dut.result.value.signed_integer != x * y):
        dut._log.info("{} * {} = {} (should be: {})".format(x, y, dut.result.value.signed_integer, x * y))
    assert dut.result.value.signed_integer == x * y

@cocotb.test()
async def test(dut):
    dut._log.info("Start")

    dut.rst_n.value = 0
    dut.x.value = 0
    dut.y.value = 0
    dut.start.value = 0

    # Set the clock period to 50 ns (20 MHz)
    clock = Clock(dut.clk, 50, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # Test zero
    await run_case(dut, 0, 0)

    # Test ones
    await run_case(dut, 1, 1)
    await run_case(dut, 1, -1)
    await run_case(dut, -1, 1)
    await run_case(dut, -1, -1)

    # Test twos
    await run_case(dut, 2, 2)
    await run_case(dut, 2, -2)
    await run_case(dut, -2, 2)
    await run_case(dut, -2, -2)

    # Test threes
    await run_case(dut, 3, 3)
    await run_case(dut, 3, -3)
    await run_case(dut, -3, 3)
    await run_case(dut, -3, -3)

    # Test maximas
    await run_case(dut, 127, 127)
    await run_case(dut, 127, -128)
    await run_case(dut, -128, 127)
    await run_case(dut, -128, -128)

    # Run all
    dut._log.info("Run all")
    for x in range(-128, 128):
        dut._log.info("Run x: {}".format(x))
        for y in range(-128, 128):
            await run_case(dut, x, y)

