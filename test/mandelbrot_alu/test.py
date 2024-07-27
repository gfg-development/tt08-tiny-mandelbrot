# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

SCALING = 2**9

async def model(dut, zr, zi, cr, ci):
    m1 = zr * zr
    m2 = zi * zi
    m3 = zr * zi

    dut.in_zr.value = zr
    dut.in_zi.value = zi
    dut.in_cr.value = cr
    dut.in_ci.value = ci

    await ClockCycles(dut.clk, 2)

    assert dut.alu.m1.value.signed_integer == m1
    assert dut.alu.m2.value.signed_integer == m2
    assert dut.alu.m3.value.signed_integer == m3

    t_zr = (m1 - m2) + cr * SCALING
    t_zi = 2 * m3 + ci * SCALING

    if t_zr >= 2 * SCALING * SCALING or t_zr < -2 * SCALING * SCALING or t_zi >= 2 * SCALING * SCALING or t_zi < -2 * SCALING * SCALING:
        assert dut.alu.overflow.value == 1
    else:
        assert dut.alu.t_zr.value.signed_integer == t_zr
        assert dut.alu.t_zi.value.signed_integer == t_zi

        assert dut.alu.out_zr.value.signed_integer == t_zr // SCALING
        assert dut.alu.out_zi.value.signed_integer == t_zi // SCALING

        assert dut.alu.overflow.value == 0

    if (m1 + m2) > 4 * SCALING * SCALING: 
        assert dut.alu.size.value == 1
    else:
        assert dut.alu.size.value == 0


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Test zeros
    await model(dut, 0, 0, 0, 0)

    # Test addition of c
    await model(dut, 0, 0, 1, 2)
    await model(dut, 0, 0, -2, -1)

    # Test calculation of z
    await model(dut, SCALING // 2, SCALING // 2, 0, 0)
    await model(dut, SCALING, 0, 0, 0)
    await model(dut, 0, SCALING, 0, 0)
    await model(dut, SCALING // 2, 0, 0, 0)
    await model(dut, 0, SCALING // 2, 0, 0)

    await model(dut, -SCALING // 2, -SCALING // 2, 0, 0)
    await model(dut, -SCALING, 0, 0, 0)
    await model(dut, 0, -SCALING, 0, 0)
    await model(dut, -SCALING // 2, 0, 0, 0)
    await model(dut, 0, -SCALING // 2, 0, 0)


    # Test calculation of size
    await model(dut, SCALING, SCALING, 0, 0)
    await model(dut, -SCALING, -SCALING, 0, 0)
    await model(dut, SCALING, -SCALING, 0, 0)
    await model(dut, -SCALING, SCALING, 0, 0)
    await model(dut, SCALING + SCALING // 2, SCALING + SCALING // 2, 0, 0)
    await model(dut, -SCALING + SCALING // 2, -SCALING + SCALING // 2, 0, 0)
    await model(dut, SCALING + SCALING // 2, -SCALING + SCALING // 2, 0, 0)
    await model(dut, -SCALING + SCALING // 2, SCALING + SCALING // 2, 0, 0)

    await model(dut, - 2 * SCALING, 0, 0, 0)
