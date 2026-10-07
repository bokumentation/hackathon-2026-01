import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

E5_RDN = [
    "100111","011101","101101","110001","110101","101001","011001","111000",
    "111001","100101","010101","110100","001101","101100","011100","010111",
    "011011","100011","010011","110010","001011","101010","011010","111010",
    "110011","100110","010110","110110","001110","101110","011110","101011",
]
E5_RDP = [
    "011000","100010","010010","110001","001010","101001","011001","000111",
    "000110","100101","010101","110100","001101","101100","011100","101000",
    "100100","100011","010011","110010","001011","101010","011010","000101",
    "001100","100110","010110","001001","001110","101110","011110","010100",
]
K28_RDN, K28_RDP = "001111", "110000"
D4_RDN = ["1011","1001","0101","1100","1101","1010","0110","1110"]
D4_RDP = ["0100","1001","0101","0011","0010","1010","0110","0001"]
K4_RDN = ["1011","0110","1010","1100","1101","0101","1001","0111"]
K4_RDP = ["0100","1001","0101","0011","0010","1010","0110","1000"]
A7_RDN, A7_RDP = "0111", "1000"
A7_X = {0: {17, 18, 20}, 1: {11, 13, 14}}

K28_5 = 0xBC
COMMA_CODES = {int("0011111010", 2), int("1100000101", 2)}


def model(data, is_k, rd):
    x, y = data & 0x1F, (data >> 5) & 0x7
    if is_k and x == 0x1C:
        s6 = K28_RDN if rd == 0 else K28_RDP
    else:
        s6 = (E5_RDN if rd == 0 else E5_RDP)[x]
    rd_mid = rd if s6.count("1") == 3 else 1 - rd
    if is_k:
        s4 = (K4_RDN if rd_mid == 0 else K4_RDP)[y]
    elif y == 7 and x in A7_X[rd_mid]:
        s4 = A7_RDN if rd_mid == 0 else A7_RDP
    else:
        s4 = (D4_RDN if rd_mid == 0 else D4_RDP)[y]
    rd_next = rd_mid if s4.count("1") == 2 else 1 - rd_mid
    return int(s6 + s4, 2), rd_next


async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.serial_in.value = 0
    dut.fault_ack.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def send_symbol(dut, code):
    emitted = None
    for i in range(10):
        dut.serial_in.value = (code >> i) & 1
        await RisingEdge(dut.clk)
        await Timer(1, unit="step")
        if int(dut.symbol_valid.value) == 1:
            emitted = (int(dut.symbol.value), int(dut.comma.value))
    return emitted


@cocotb.test()
async def test_lock_and_aligned_symbols(dut):
    await setup(dut)
    seq = [K28_5, K28_5, 0x00, 0xAB, 0x3F, K28_5, 0x11, 0x22, 0x7E, K28_5]
    rd = 0
    codes = []
    for data in seq:
        is_k = 1 if data == K28_5 else 0
        code, rd = model(data, is_k, rd)
        codes.append(code)

    emitted = []
    for code in codes:
        e = await send_symbol(dut, code)
        if e is not None:
            emitted.append(e)

    assert int(dut.word_lock.value) == 1, "word lock not acquired"
    assert len(emitted) == len(codes), f"emitted {len(emitted)} of {len(codes)}"
    for (sym, cm), code in zip(emitted, codes):
        assert sym == code, f"symbol {sym:#012b} != {code:#012b}"
        assert cm == (1 if code in COMMA_CODES else 0), "comma flag mismatch"
    dut._log.info("locked and emitted %d aligned symbols", len(emitted))


@cocotb.test()
async def test_timeout_and_relock(dut):
    await setup(dut)
    rd = 0
    comma, rd = model(K28_5, 1, rd)
    await send_symbol(dut, comma)
    assert int(dut.word_lock.value) == 1, "did not lock on comma"

    for i in range(140):
        code, rd = model(i & 0xFF, 0, rd)
        await send_symbol(dut, code)

    assert int(dut.timeout_fault.value) == 1, "timeout not raised"
    assert int(dut.word_lock.value) == 0, "word lock not dropped on timeout"

    dut.fault_ack.value = 1
    await RisingEdge(dut.clk)
    dut.fault_ack.value = 0
    await RisingEdge(dut.clk)

    comma, rd = model(K28_5, 1, rd)
    await send_symbol(dut, comma)
    assert int(dut.word_lock.value) == 1, "did not relock after timeout"
    dut._log.info("timeout, lock drop, ack, and relock ok")
