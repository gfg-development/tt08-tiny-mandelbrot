# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge

WIDTH = 320
HEIGHT = 240

SCALING = 4
CR_OFFSET = - (511 * WIDTH // 640) * SCALING
CI_OFFSET = - (HEIGHT // 2) * SCALING
MAX_CTR = 15

def read_ppm(fname):
    with open(fname) as f:
        # Ignore the header
        for _ in range(3):
            f.readline()
        pixel_values = []

        for line in f:
            pixel_values.extend([int(x) for x in line.split()])
    return pixel_values

async def configure(dut):
    # Load configuration via shift register
    configuration = (MAX_CTR << 26) | ((SCALING - 1) << 22) | ((CI_OFFSET & 0x7FF) << 11) | (CR_OFFSET & 0x7FF)

    dut.ui_in[4].value = 1

    for _ in range(33):
        dut.ui_in[5].value = configuration & 0x1
        configuration = configuration >> 1
        await ClockCycles(dut.clk, 1)
    dut.ui_in[4].value = 0
    await ClockCycles(dut.clk, 10)

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

    dut._log.info("Test project behavior in RP2040 mode")

    await configure(dut)
    
    # Start rendering
    dut.ui_in[0].value = 1
    await ClockCycles(dut.clk, 1)
    dut.ui_in[0].value = 0

    await FallingEdge(dut.user_project.finished)

    golden_image = read_ppm("image_15_4_-1020_-480.golden.ppm")
    image = []

    with open("image_{}_{}_{}_{}.ppm".format(MAX_CTR, SCALING, CR_OFFSET, CI_OFFSET), "w+") as f:
        f.write("P2\r\n{} {}\r\n15\r\n".format(WIDTH, HEIGHT))
        for y in range(HEIGHT):
            dut._log.info("Line: {}".format(y))
            for _ in range(WIDTH):
                await FallingEdge(dut.user_project.running)
                await RisingEdge(dut.clk)
                pixel_value = int(str(dut.uo_out.value[4 : 7]), 2)
                image.append(pixel_value)
                f.write("{} ".format(pixel_value))
            f.write("\r\n")

    # Finish flag is set
    assert dut.uo_out[5].value == 1

    # Ensure that the image is the golden one
    for (x, y) in zip(golden_image, image):
        assert x == y

@cocotb.test()
async def test_vga_mode(dut):
    dut._log.info("Start")

    # Set the clock period to 50 ns (20 MHz)
    clock = Clock(dut.clk, 50, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 10)

    dut._log.info("Test project behavior in VGA mode")

    await configure(dut)
    
    # Start rendering
    dut.ui_in[0].value = 1
    await ClockCycles(dut.clk, 1)
    dut.ui_in[0].value = 0

    # Wait for image to be generated
    await RisingEdge(dut.user_project.finished)

    await ClockCycles(dut.clk, 1024*1024)