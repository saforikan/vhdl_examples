from pathlib import Path
from vunit import VUnit
import os

os.environ['VUNIT_SIMULATOR'] = "ghdl"
os.environ['VUNIT_GHDL_PATH'] = os.path.expanduser("~/devel/ghdl3/bin")

ROOT = Path(__file__).parent / ".."
IP_PATH = ROOT / "ip"

ip_list = [
    "timestamp_csr"
]

VU = VUnit.from_argv(compile_builtins=False)
VU.add_vhdl_builtins()
VU.add_com()
VU.add_osvvm()
VU.add_verification_components()

VU.enable_location_preprocessing()
VU.enable_check_preprocessing()

# add utils
demo = VU.add_library("demo")
utils = [f for f in os.listdir(os.path.join(ROOT, "ip/util/")) if os.path.isfile(os.path.join(os.path.join(ROOT, "ip/util/"), f))]
demo.add_source_files([os.path.join(ROOT, "ip/util/", f) for f in utils])

simlib = VU.add_library("simlib")
sims = [f for f in os.listdir(os.path.join(ROOT, "ip/sim/")) if os.path.isfile(os.path.join(os.path.join(ROOT, "ip/sim/"), f))]
simlib.add_source_files([os.path.join(ROOT, "ip/sim/", f) for f in sims])

# add IP
lib = VU.add_library("lib")
for path in ip_list:
    lib.add_source_files(Path("../ip") / path / "*.vhd")

tcl_after_load = []
component = ""

VU.set_sim_option("ghdl.elab_flags", ["-frelaxed"])

VU.main()
