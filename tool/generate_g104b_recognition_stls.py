import math
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "smoke" / "g104b_primitives"
OUT.mkdir(parents=True, exist_ok=True)


def write(name, triangles):
    with (OUT / f"{name}.stl").open("w", encoding="ascii") as stream:
        stream.write(f"solid {name}\n")
        for a, b, c in triangles:
            ux, uy, uz = (b[i] - a[i] for i in range(3))
            vx, vy, vz = (c[i] - a[i] for i in range(3))
            nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
            length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
            stream.write(f" facet normal {nx/length} {ny/length} {nz/length}\n  outer loop\n")
            for point in (a, b, c):
                stream.write(f"   vertex {point[0]} {point[1]} {point[2]}\n")
            stream.write("  endloop\n endfacet\n")
        stream.write(f"endsolid {name}\n")


def grid(surface, nu, nv, wrap_u=False):
    vertices = [[surface(i / nu, j / nv) for j in range(nv + 1)] for i in range(nu + 1)]
    triangles = []
    u_count = nu if wrap_u else nu
    for i in range(u_count):
        ni = (i + 1) % nu if wrap_u and i + 1 == nu else i + 1
        for j in range(nv):
            a, b, c, d = vertices[i][j], vertices[ni][j], vertices[ni][j + 1], vertices[i][j + 1]
            triangles.extend([(a, b, c), (a, c, d)])
    return triangles


write("plane", grid(lambda u, v: ((u - .5) * 40, (v - .5) * 40, 0), 12, 12))
write("cone", grid(lambda u, v: ((4 + 12 * v) * math.cos(2 * math.pi * u), (4 + 12 * v) * math.sin(2 * math.pi * u), 35 * v), 48, 14, True))
write("sphere", grid(lambda u, v: (18 * math.sin(math.pi * (.02 + .96 * v)) * math.cos(2 * math.pi * u), 18 * math.sin(math.pi * (.02 + .96 * v)) * math.sin(2 * math.pi * u), 18 * math.cos(math.pi * (.02 + .96 * v))), 48, 24, True))
write("torus", grid(lambda u, v: ((24 + 7 * math.cos(2 * math.pi * v)) * math.cos(2 * math.pi * u), (24 + 7 * math.cos(2 * math.pi * v)) * math.sin(2 * math.pi * u), 7 * math.sin(2 * math.pi * v)), 48, 20, True))
