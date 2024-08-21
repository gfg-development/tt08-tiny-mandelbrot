# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer, First
from cocotb.utils import get_sim_time

WIDTH = 400
HEIGHT = 300

SCALING = 4*2**5
CR_OFFSET = - (511 * WIDTH // 640) * SCALING
CI_OFFSET = - (HEIGHT // 2) * SCALING
MAX_CTR = 15

def read_ppm(fname, rgb=False):
    with open(fname) as f:
        # Ignore the header
        for _ in range(3):
            f.readline()
        pixel_values = []

        for line in f:
            rgb_values = [int(x) for x in line.strip().split()]
            if rgb:
                for i in range(len(rgb_values) // 3):
                    pixel_values.append((rgb_values[3 * i], rgb_values[3 * i + 1], rgb_values[3 * i + 2]))
            else:
                pixel_values.extend(rgb_values)
    return pixel_values

async def configure(dut):
    # Load configuration via shift register
    configuration = (MAX_CTR << 42) | ((SCALING - 1) << 32) | ((CI_OFFSET & 0xFFFF) << 16) | (CR_OFFSET & 0xFFFF)
    dut._log.info("Configuration: {:X}".format(configuration))

    dut.ui_in[0].value = 1
    dut.ui_in[2].value = 0

    for _ in range(52):
        dut.ui_in[1].value = configuration & 0x1
        configuration = configuration >> 1
        dut.ui_in[2].value = 0
        await ClockCycles(dut.clk, 1)
        dut.ui_in[2].value = 1
        await ClockCycles(dut.clk, 1)
    dut.ui_in[0].value = 0
    dut.ui_in[2].value = 0

@cocotb.test()
async def test_rp2040_mode(dut):
    dut._log.info("Start")

    # Set the clock period to 25 ns (40 MHz)
    clock = Clock(dut.clk, 25, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 8
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 10)

    dut._log.info("Test project behavior in RP2040 mode")

    await configure(dut)
    
    dut._log.info("Configured parameters")

    timeout = Timer(1000, "ns")
    ret = await First(FallingEdge(dut.finished), timeout)
    assert ret != timeout

    dut._log.info("Rendering started")

    golden_image = read_ppm("image_15_128_-40832_-19200.golden.ppm")
    image = []

    with open("image_{}_{}_{}_{}.ppm".format(MAX_CTR, SCALING, CR_OFFSET, CI_OFFSET), "w+") as f:
        f.write("P2\r\n{} {}\r\n15\r\n".format(WIDTH, HEIGHT))
        for y in range(HEIGHT):
            dut._log.info("Line: {}".format(y))
            for _ in range(WIDTH):
                timeout = Timer(5000, "ns")
                ret = await First(FallingEdge(dut.running), timeout)
                assert ret != timeout

                await RisingEdge(dut.clk)
                pixel_value = int(str(dut.uo_out.value[4 : 7]), 2)
                image.append(pixel_value)
                f.write("{} ".format(pixel_value))
            f.write("\r\n")

    # Finish flag is set
    assert dut.uo_out[5].value == 1

    # Ensure that the image is the golden one
    for (i, (x, y)) in enumerate(zip(golden_image, image)):
        if x != y:
            dut._log.error("{} != {} @ {}", x, y, i)
        assert x == y

VSYNC_MASK = 0x08
HSYNC_MASK = 0x80

VGA_WIDTH               =  800
LINE_VISIBLE_AREA       =  800 * 25
LINE_FRONT_PORCH        =   40 * 25
LINE_SYNC_PULSE         =  128 * 25
LINE_BACK_PORCH         =   88 * 25
WHOLE_LINE              = 1056 * 25

VGA_HEIGHT              = 600
FRAME_VISIBLE_AREA      = 600 * WHOLE_LINE
FRAME_FRONT_PORCH       =   1 * WHOLE_LINE
FRAME_SYNC_PULSE        =   4 * WHOLE_LINE
FRAME_BACK_PORCH        =  23 * WHOLE_LINE
WHOLE_FRAME             = 628 * WHOLE_LINE

RGB_MASK                = 0x77

@cocotb.test()
async def test_mode_vga(dut):
    dut._log.info("Start")

    # Set the clock period to 25 ns (40 MHz)
    clock = Clock(dut.clk, 25, units="ns")
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
    
    dut._log.info("Configured parameters")

    last_vsync_start = None
    last_vsync_end = None
    last_hsync_start = None
    last_hsync_end = None
    
    old_vsync = int(dut.vsync.value)
    old_hsync = int(dut.hsync.value)

    frame_nr = 0
    pixel_nr = 0
    image = []

    framebuffer = [0] * (WIDTH * HEIGHT + 1)
    read_ptr_h = 0
    read_ptr_v = 0
    write_ptr = 0

    old_write = int(dut.write.value)
    old_read = int(dut.read.value)
    old_reset_write_ptr = int(dut.reset_write_ptr.value)
    old_reset_read_ptr = int(dut.reset_read_ptr.value)

    shift_framebuffer = [0, 0]                

    for _ in range(15 * 1056 * 628):
        time = get_sim_time("ns")
        if dut.vsync.value == 1 and old_vsync == 0:
            if last_vsync_start != None:
                assert time - last_vsync_start == WHOLE_FRAME
                assert pixel_nr == 800 * 600

            last_vsync_start = time
            
            if frame_nr != 0:
                f.close()

            frame_nr += 1
            
            f = open("image_vga_{}_{}_{}_{}_{}.ppm".format(frame_nr, MAX_CTR, SCALING, CR_OFFSET, CI_OFFSET), "w+")
            f.write("P3\r\n{} {}\r\n3\r\n".format(VGA_WIDTH, VGA_HEIGHT))

            dut.log.info("VSync - start of frame {}".format(frame_nr))
            
            if frame_nr == 14:
                dut.log.info("Got 14 frames, compare the last one to the golden one")
                break

            pixel_nr = 0
            image = []

        if dut.vsync.value == 0 and old_vsync == 1:
            dut.log.info("VSync end")
            last_vsync_end = time
            assert last_vsync_end - last_vsync_start == FRAME_SYNC_PULSE

        if dut.hsync.value == 1 and old_hsync == 0:
            dut.log.info("HSync start")
            if last_hsync_start is not None:
                assert time - last_hsync_start == WHOLE_LINE

            if last_vsync_start is not None:
                assert ((time - last_vsync_start) % WHOLE_LINE) == LINE_FRONT_PORCH

            last_hsync_start = time

            if frame_nr != 0:
                f.write("\r\n")

        if dut.hsync.value == 0 and old_hsync == 1:
            dut.log.info("HSync end")
            dut.log.info("Read pointers: {} {}".format(read_ptr_h, read_ptr_v))
            last_hsync_end = time
            if last_hsync_start is not None:
                assert last_hsync_end - last_hsync_start == LINE_SYNC_PULSE

        if last_vsync_end is not None and last_hsync_end is not None:
            visible_area = (
                ((time - last_hsync_end) >= LINE_BACK_PORCH) and
                ((time - last_hsync_end) < (LINE_VISIBLE_AREA + LINE_BACK_PORCH)) and
                ((time - last_vsync_end) >= FRAME_BACK_PORCH) and
                ((time - last_vsync_end) < (FRAME_VISIBLE_AREA + FRAME_BACK_PORCH))
            )
        else:
            visible_area = False

        assert ((dut.uo_out.value & RGB_MASK) == 0) or visible_area

        if frame_nr != 0 and visible_area:
            if last_vsync_start != None:
                r_value = int(dut.red.value)
                g_value = int(dut.green.value)
                b_value = int(dut.blue.value)
                f.write("{} {} {}    ".format(r_value, g_value, b_value))
                image.append((r_value, g_value, b_value))

        if visible_area:
            pixel_nr += 1

        # Handel the framebuffer
        if dut.reset_read_ptr.value == 1 and old_reset_read_ptr == 0:
            read_ptr_h = 0
            read_ptr_v = 0
            dut.log.info("Reset read pointer")

        if dut.reset_write_ptr.value == 1 and old_reset_write_ptr == 0:
            write_ptr = 0
            dut.log.info("Reset write pointer")

        if dut.write.value == 1 and old_write == 0:
            framebuffer[write_ptr] = int(dut.write_data.value)
            write_ptr += 1


        if dut.read.value == 1 and old_read == 0:
            read_ptr_h += 1

            if read_ptr_h == WIDTH:
                read_ptr_h = 0
                read_ptr_v += 1

        assert read_ptr_h < WIDTH
        assert read_ptr_v // 2 <= HEIGHT

        dut.ui_in.value = shift_framebuffer[0] * 16
        shift_framebuffer = [framebuffer[read_ptr_h + (read_ptr_v // 2) * WIDTH], shift_framebuffer[1]]

        old_vsync           = int(dut.vsync.value)
        old_hsync           = int(dut.hsync.value)

        old_write           = int(dut.write.value)
        old_read            = int(dut.read.value)
        old_reset_write_ptr = int(dut.reset_write_ptr.value)
        old_reset_read_ptr  = int(dut.reset_read_ptr.value)

        await ClockCycles(dut.clk, 1)

    # Ensure that the image is the golden one
    golden_image = read_ppm("image_vga_15_128_-40832_-19200.golden.ppm", True)
    for (i, (x, y)) in enumerate(zip(golden_image, image)):
        if x != y:
            dut._log.error("{} != {} @ {}", x, y, i)
        assert x == y