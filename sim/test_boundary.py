import cocotb
from cocotb.triggers import RisingEdge

TIMEOUT_CYCLES = 4096


async def reset(dut, cycles=4):
    dut.rst_n.value = 0
    dut.pos_edge.value = 0
    dut.neg_edge.value = 0
    dut.transmission_begin.value = 0
    dut.crc_ok.value = 0
    dut.frame_done.value = 0
    dut.fault_ack.value = 0
    dut.frame_data.value = 0
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def start_frame(dut):
    dut.transmission_begin.value = 1
    await RisingEdge(dut.clk)
    dut.transmission_begin.value = 0
    await RisingEdge(dut.clk)


async def commit(dut, data=0x123456789ABCDEF012345678):
    dut.frame_data.value = data
    dut.frame_done.value = 1
    await RisingEdge(dut.clk)
    dut.frame_done.value = 0


@cocotb.test()
async def test_clean_frame_commits(dut):
    await reset(dut)
    await start_frame(dut)
    assert int(dut.framing_ok.value) == 1
    dut.crc_ok.value = 1
    await commit(dut)
    await RisingEdge(dut.clk)
    dut._log.info(
        "accept: host_full=%d fault=%d data=%024X",
        int(dut.host_full.value),
        int(dut.fault.value),
        int(dut.host_data_q.value),
    )
    assert int(dut.host_full.value) == 1
    assert int(dut.fault.value) == 0
    assert int(dut.host_data_q.value) == 0x123456789ABCDEF012345678


@cocotb.test()
async def test_integrity_fail_is_rejected(dut):
    await reset(dut)
    await start_frame(dut)
    dut.crc_ok.value = 0
    await commit(dut)
    await RisingEdge(dut.clk)
    dut._log.info("reject: host_full=%d fault=%d", int(dut.host_full.value), int(dut.fault.value))
    assert int(dut.host_full.value) == 0
    assert int(dut.fault.value) == 1


@cocotb.test()
async def test_fault_is_sticky_until_ack(dut):
    await reset(dut)
    await start_frame(dut)
    dut.crc_ok.value = 0
    await commit(dut)
    await RisingEdge(dut.clk)
    assert int(dut.fault.value) == 1
    for _ in range(8):
        await RisingEdge(dut.clk)
        assert int(dut.fault.value) == 1
    dut.fault_ack.value = 1
    await RisingEdge(dut.clk)
    dut.fault_ack.value = 0
    await RisingEdge(dut.clk)
    assert int(dut.fault.value) == 0


@cocotb.test()
async def test_timing_violation_is_rejected(dut):
    await reset(dut)
    await start_frame(dut)
    assert int(dut.framing_ok.value) == 1
    dut.pos_edge.value = 1
    await RisingEdge(dut.clk)
    dut.pos_edge.value = 0
    dut.neg_edge.value = 1
    await RisingEdge(dut.clk)
    dut.neg_edge.value = 0
    await RisingEdge(dut.clk)
    dut._log.info(
        "timing: framing_ok=%d timing_fault=%d",
        int(dut.framing_ok.value),
        int(dut.timing_fault.value),
    )
    assert int(dut.timing_fault.value) == 1
    assert int(dut.framing_ok.value) == 0
    dut.crc_ok.value = 1
    await commit(dut)
    await RisingEdge(dut.clk)
    assert int(dut.host_full.value) == 0
    assert int(dut.fault.value) == 1


@cocotb.test()
async def test_timeout_is_rejected(dut):
    await reset(dut)
    await start_frame(dut)
    for _ in range(TIMEOUT_CYCLES + 8):
        await RisingEdge(dut.clk)
    dut._log.info(
        "timeout: framing_ok=%d timeout_fault=%d",
        int(dut.framing_ok.value),
        int(dut.timeout_fault.value),
    )
    assert int(dut.timeout_fault.value) == 1
    assert int(dut.framing_ok.value) == 0


@cocotb.test()
async def test_commit_latency(dut):
    await reset(dut)
    await start_frame(dut)
    dut.crc_ok.value = 1
    dut.frame_data.value = 0xA5A5A5A5A5A5A5A5A5A5A5A5
    dut.frame_done.value = 1
    await RisingEdge(dut.clk)
    dut.frame_done.value = 0
    latency = 0
    while int(dut.host_full.value) == 0 and latency < 8:
        await RisingEdge(dut.clk)
        latency += 1
    dut._log.info("commit latency = %d cycle(s)", latency)
    assert 1 <= latency <= 3
