import random


def dot4(a, b):
    if len(a) != 4 or len(b) != 4:
        raise ValueError("four lanes required")
    if any(type(x) is not int or not -128 <= x <= 127 for x in (*a, *b)):
        raise ValueError("signed INT8 required")
    return sum(x * y for x, y in zip(a, b))


def pack(lanes):
    return sum((x & 255) << (8 * i) for i, x in enumerate(lanes))


if __name__ == "__main__":
    rng = random.Random(42)
    cases = [([x]*4, [y]*4) for x in (-128, 0, 127) for y in (-128, 0, 127)]
    for _ in range(256):
        cases.append(tuple([rng.randrange(-128, 128) for _ in range(4)] for _ in range(2)))
    for a, b in cases:
        print(f"{pack(a):08x}{pack(b):08x}{dot4(a,b) & 0xffffffff:08x}")
