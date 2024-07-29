# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_rp2040_mode(dut):
    dut._log.info("Start")

    # Set the clock period to 50 ns (20 MHz)
    clock = Clock(dut.clk, 50, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 128
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 10)

    dut._log.info("Test project behavior")

    # Load configuration via shift register
    configuration = 0b000111100000000000000000000000000

    dut.ui_in[4].value = 1

    for _ in range(33):
        dut.ui_in[5].value = configuration & 0x1
        configuration = configuration >> 1
        await ClockCycles(dut.clk, 1)


    dut.ui_in[4].value = 0

    await ClockCycles(dut.clk, 10)
    
    # Start rendering
    dut.ui_in[0].value = 1
    await ClockCycles(dut.clk, 128)

    # Finish flag is set
    assert dut.uo_out[5].value == 1