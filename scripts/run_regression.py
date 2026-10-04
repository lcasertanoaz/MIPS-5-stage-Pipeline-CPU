#!/usr/bin/env python3
"""Run every testbench in tb/ (files named tb_*.v or tb_*.sv) and summarize.

Each testbench prints "TEST PASSED" on success, or a line containing
"FAIL"/"ERROR" on failure. Memory images in mem/ are copied into each run
directory so $readmemh finds them.

Usage:
  python3 scripts/run_regression.py              # Vivado xsim
  python3 scripts/run_regression.py --sim iverilog
  python3 scripts/run_regression.py --sva        # xsim, also compiling verif/*.sv
  python3 scripts/run_regression.py -k vbsme     # only matching testbenches
"""
import argparse, glob, os, re, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = sorted(glob.glob(os.path.join(ROOT, "src", "*.v")))      # src/fpga/ is board-only
SVA = sorted(glob.glob(os.path.join(ROOT, "verif", "*.sv")))
TBS = sorted(glob.glob(os.path.join(ROOT, "tb", "tb_*.v")) +
             glob.glob(os.path.join(ROOT, "tb", "tb_*.sv")))
MEM = glob.glob(os.path.join(ROOT, "mem", "*.mem"))
BUILD = os.path.join(ROOT, "build")

def sh(cmd, cwd):
    p = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True, errors="replace")
    return p.returncode, p.stdout + p.stderr

def q(paths):
    return " ".join(f'"{p}"' for p in paths)

def run_iverilog(tb, top, wd):
    rc, out = sh(f"iverilog -g2012 -o sim.vvp -s {top} {q(SRC + [tb])}", wd)
    if rc:
        return None, out
    return sh("vvp -n sim.vvp", wd)[1], out

def run_xsim(tb, top, wd):
    v_files = [f for f in SRC + [tb] if f.endswith(".v")]
    sv_files = SVA + [f for f in [tb] if f.endswith(".sv")]
    log = ""
    defs = "-d USE_SVA " if SVA else ""          # tells tb_vbsme to instantiate cpu_sva
    rc, out = sh(f"xvlog {defs}{q(v_files)}", wd); log += out
    if rc == 0 and sv_files:
        rc, out = sh(f"xvlog --sv {q(sv_files)}", wd); log += out
    if rc == 0:
        rc, out = sh(f"xelab -debug typical {top} -s {top}_snap", wd); log += out
    if rc:
        return None, log
    return sh(f"xsim {top}_snap -R", wd)[1], log

def verdict(sim_log):
    if re.search(r"\bFAIL\b|^\s*Error:|ERROR:", sim_log, re.M):
        return "FAIL"
    if "TEST PASSED" in sim_log:
        return "PASS"
    return "NO RESULT"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", choices=["xsim", "iverilog"], default="xsim")
    ap.add_argument("-k", help="only run testbenches whose name contains this")
    ap.add_argument("--sva", action="store_true",
                    help="xsim only: also compile verif/*.sv (assertions; work in progress)")
    ap.add_argument("--no-sva", action="store_true", help=argparse.SUPPRESS)  # old flag, now the default
    args = ap.parse_args()
    global SVA
    if not args.sva:
        SVA = []

    tool = "xvlog" if args.sim == "xsim" else "iverilog"
    if not shutil.which(tool):
        sys.exit(f"{tool} not found on PATH (for xsim, source Vivado's settings64 script first)")
    tbs = [t for t in TBS if not args.k or args.k in os.path.basename(t)]
    if not tbs:
        sys.exit("No testbenches found (expected tb/tb_*.v or tb/tb_*.sv)")

    results = []
    for tb in tbs:
        top = os.path.splitext(os.path.basename(tb))[0]   # module name = file name
        wd = os.path.join(BUILD, args.sim, top)
        os.makedirs(wd, exist_ok=True)
        for m in MEM:
            shutil.copy(m, wd)
        sim_log, build_log = (run_xsim if args.sim == "xsim" else run_iverilog)(tb, top, wd)
        with open(os.path.join(wd, "build.log"), "w") as f:
            f.write(build_log)
        if sim_log is None:
            v = "BUILD ERROR"
        else:
            with open(os.path.join(wd, "sim.log"), "w") as f:
                f.write(sim_log)
            v = verdict(sim_log)
            for line in sim_log.splitlines():   # echo the testbench summary lines
                if line.startswith(("ok", "FAIL", "cycles=", "assertions:", "TEST PASSED")):
                    print("    " + line)
        results.append((top, v))
        print(f"{v:12} {top}")

    passed = sum(v == "PASS" for _, v in results)
    print(f"\n{passed}/{len(results)} testbenches passed  (logs: build/{args.sim}/<tb>/)")
    sys.exit(0 if passed == len(results) else 1)

if __name__ == "__main__":
    main()
