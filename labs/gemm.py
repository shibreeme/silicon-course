"""Tiled integer matrix multiplication using the same four-lane contract as dot4.sv."""
from random import Random
from golden import dot4


def tiled_gemm(a, b):
    if not a or not b or not b[0]:
        raise ValueError("expected two nonempty matrices")
    depth, columns = len(b), len(b[0])
    if any(len(row) != depth for row in a) or any(len(row) != columns for row in b):
        raise ValueError("incompatible matrix shapes")
    output = [[0] * columns for _ in a]
    for row_base in range(0, len(a), 4):
        for col_base in range(0, columns, 4):
            for k in range(0, depth, 4):
                width = min(4, depth - k)
                for i in range(row_base, min(row_base + 4, len(a))):
                    lhs = list(a[i][k:k + width]) + [0] * (4 - width)
                    for j in range(col_base, min(col_base + 4, columns)):
                        rhs = [b[t][j] for t in range(k, k + width)] + [0] * (4 - width)
                        output[i][j] += dot4(lhs, rhs)
    return output


if __name__ == "__main__":
    rng = Random(41)
    for rows, depth, cols in [(1, 1, 1), (8, 8, 8), (5, 7, 3), (3, 5, 6)]:
        a = [[rng.randrange(-128, 128) for _ in range(depth)] for _ in range(rows)]
        b = [[rng.randrange(-128, 128) for _ in range(cols)] for _ in range(depth)]
        expected = [[sum(x * y for x, y in zip(row, column)) for column in zip(*b)] for row in a]
        assert tiled_gemm(a, b) == expected
    print("PASS: 4 matrix shapes, including partial tiles")
