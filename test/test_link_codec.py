import random

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

K_SYMBOLS = [0x1C, 0x3C, 0x5C, 0x7C, 0x9C, 0xBC, 0xDC, 0xFC, 0xF7, 0xFB, 0xFD, 0xFE]


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
    dut.enc_valid.value = 0
    dut.enc_is_k.value = 0
    dut.enc_din.value = 0
    dut.dec_valid.value = 0
    dut.dec_din.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    dut.enc_valid.value = 1
    dut.dec_valid.value = 1


async def reset(dut):
    dut.enc_valid.value = 0
    dut.dec_valid.value = 0
    dut.rst_n.value = 0
    for _ in range(2):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    dut.enc_valid.value = 1
    dut.dec_valid.value = 1


async def enc(dut, data, is_k):
    dut.enc_din.value = data
    dut.enc_is_k.value = 1 if is_k else 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="step")
    return int(dut.enc_dout.value)


async def dec(dut, code):
    dut.dec_din.value = code
    await RisingEdge(dut.clk)
    await Timer(1, unit="step")
    return (
        int(dut.dec_dout.value),
        int(dut.dec_is_k.value),
        int(dut.dec_code_error.value),
        int(dut.dec_disp_error.value),
    )


@cocotb.test()
async def test_known_vectors(dut):
    await setup(dut)
    await reset(dut)

    assert await enc(dut, 0x00, 0) == int("1001110100", 2), "D0.0 RD- mismatch"

    await reset(dut)
    assert await enc(dut, 0x3F, 0) == int("1010111001", 2), "D31.1 RD- mismatch"

    await reset(dut)
    assert await enc(dut, 0xBC, 1) == int("0011111010", 2), "K28.5 RD- mismatch"
    dut._log.info("known vectors ok")


@cocotb.test()
async def test_encoder_all_data(dut):
    await setup(dut)
    await reset(dut)
    rd = 0
    for d in range(256):
        code = await enc(dut, d, 0)
        exp, rd = model(d, 0, rd)
        assert code == exp, f"D{d:#04x} code {code:#012b} != {exp:#012b}"
    dut._log.info("all 256 data symbols encoded correctly")


@cocotb.test()
async def test_encoder_all_k(dut):
    await setup(dut)
    await reset(dut)
    rd = 0
    for k in K_SYMBOLS:
        code = await enc(dut, k, 1)
        exp, rd = model(k, 1, rd)
        assert code == exp, f"K{k:#04x} code {code:#012b} != {exp:#012b}"
    dut._log.info("all 12 K symbols encoded correctly")


@cocotb.test()
async def test_roundtrip_sequence(dut):
    await setup(dut)
    await reset(dut)
    random.seed(0x8B10B)
    rd = 0
    seq = []
    for _ in range(600):
        if random.random() < 0.15:
            seq.append((random.choice(K_SYMBOLS), 1))
        else:
            seq.append((random.randrange(256), 0))

    codes = []
    for data, is_k in seq:
        code = await enc(dut, data, is_k)
        exp, rd = model(data, is_k, rd)
        assert code == exp, "encoder/model mismatch in sequence"
        codes.append(code)

    await reset(dut)
    for (data, is_k), code in zip(seq, codes):
        got, got_k, cerr, derr = await dec(dut, code)
        assert got == data, f"decoded {got:#04x} != {data:#04x}"
        assert got_k == is_k, "is_k mismatch"
        assert cerr == 0 and derr == 0, "false error on valid code"
    dut._log.info("round-trip over %d symbols ok", len(seq))


@cocotb.test()
async def test_invalid_code(dut):
    await setup(dut)
    await reset(dut)
    _, _, cerr, derr = await dec(dut, 0b1111111111)
    assert cerr == 1 and derr == 0, "invalid code not flagged"
    dut._log.info("invalid code flagged")


@cocotb.test()
async def test_disparity_error(dut):
    await setup(dut)
    await reset(dut)
    _, _, cerr, derr = await dec(dut, int("0110001011", 2))
    assert derr == 1 and cerr == 0, "disparity error not flagged"
    dut._log.info("disparity error flagged")
