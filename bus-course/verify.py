"""Run every teaching design with Icarus Verilog and fail on the first regression."""
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parent
LABS = (
    ("i2c", "tb", "i2c.sv", "tb.sv"),
    ("spi", "tb_spi", "spi.sv", "tb_spi.sv"),
    ("apb", "tb_apb", "apb.sv", "tb_apb.sv"),
    ("axi", "tb", "lite.sv", "tb.sv"),
    ("axi", "tb_burst", "burst.sv", "tb_burst.sv"),
)

if __name__ == "__main__":
    with TemporaryDirectory() as output:
        for name, top, design, bench in LABS:
            image = Path(output) / (name + ".vvp")
            subprocess.run(["iverilog", "-g2012", "-Wall", "-s", top, "-o", image,
                            ROOT / name / design, ROOT / name / bench], check=True, timeout=60)
            subprocess.run(["vvp", image], cwd=output, check=True, timeout=60)
