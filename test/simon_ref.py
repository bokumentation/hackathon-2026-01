"""SIMON-32/64 reference implementation and CBC-MAC.

Written from the SIMON specification: 16-bit words, 32 rounds, 64-bit key (four
key words), and the Z0 sequence. Used as the golden source for the RTL test.

Pure Python, no third-party dependencies.
"""

WORD_BITS = 16
WORD_MASK = (1 << WORD_BITS) - 1
ROUNDS = 32
KEY_WORDS = 4
C = WORD_MASK - 3

# Z0 sequence, bit 0 first as listed in the specification.
Z0 = int(
    "11111010001001010110000111001101111101000100101011000011100110"[::-1], 2
)


def _rotr(x, r):
    return ((x >> r) | (x << (WORD_BITS - r))) & WORD_MASK


def _rotl(x, r):
    return ((x << r) | (x >> (WORD_BITS - r))) & WORD_MASK


def _f(x):
    return (_rotl(x, 1) & _rotl(x, 8)) ^ _rotl(x, 2)


def _z(bit_index):
    return (Z0 >> (bit_index % 62)) & 1


def key_schedule(key):
    k = [
        (key >> (WORD_BITS * i)) & WORD_MASK for i in range(KEY_WORDS)
    ]
    for i in range(KEY_WORDS, ROUNDS):
        tmp = _rotr(k[i - 1], 3)
        tmp ^= k[i - 3]
        tmp ^= _rotr(tmp, 1)
        k.append(C ^ _z(i - KEY_WORDS) ^ k[i - KEY_WORDS] ^ tmp)
    return k


def encrypt_block(plaintext, key):
    ks = key_schedule(key)
    x = (plaintext >> WORD_BITS) & WORD_MASK
    y = plaintext & WORD_MASK
    for i in range(ROUNDS):
        x, y = (y ^ _f(x) ^ ks[i]) & WORD_MASK, x
    return (x << WORD_BITS) | y


def cbcmac(message_words, key, iv=0):
    state = iv
    for word in message_words:
        state = encrypt_block(state ^ (word & 0xFFFFFFFF), key)
    return state


def bytes_to_words(data):
    if len(data) % 4:
        raise ValueError("length must be a multiple of 4 bytes")
    return [
        int.from_bytes(data[i : i + 4], "big") for i in range(0, len(data), 4)
    ]


def _selftest():
    key = 0x1918111009080100
    plaintext = 0x65656877
    ct = encrypt_block(plaintext, key)
    print(f"SIMON32/64 key=0x{key:016X} pt=0x{plaintext:08X} ct=0x{ct:08X}")
    return ct


if __name__ == "__main__":
    _selftest()
