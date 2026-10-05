"""Frame construction for the tt07-bep-decode protocol.

The decoder shifts bits MSB first. A frame is 192 bits:

    header (96): preamble 32, type_1 16, type_2 16, constant 32
    data   (96): thermostat_id 32, room_temp 16, set_temp 16, state 8,
                 integrity field (tail_1, tail_2, tail_3) 24
"""

PREAMBLE = 0xAAAAAAAA
TYPE_WORD = 0xD391
CONSTANT = 0x0DFFFFFE


def int_bits(value, width):
    """MSB-first bit list for a value of the given width."""
    return [(value >> (width - 1 - i)) & 1 for i in range(width)]


def header_bits():
    return (
        int_bits(PREAMBLE, 32)
        + int_bits(TYPE_WORD, 16)
        + int_bits(TYPE_WORD, 16)
        + int_bits(CONSTANT, 32)
    )


def build_frame(thermostat_id, room_temp, set_temp, state, tail):
    return (
        header_bits()
        + int_bits(thermostat_id, 32)
        + int_bits(room_temp, 16)
        + int_bits(set_temp, 16)
        + int_bits(state, 8)
        + int_bits(tail, 24)
    )


def flip(bits, index):
    """Return a copy of the bit list with one bit flipped."""
    out = list(bits)
    out[index] ^= 1
    return out
