#!/usr/bin/env python3
"""Engine benchmark: the model Elementum ships, on several engines, same machine.

Model: Qwen2.5-1.5B-Instruct Q4_K_M, the exact GGUF file Elementum downloads
(Sapient's alias qwen2.5-1.5b-q4). Every engine that reads GGUF reads that same
file from the Hugging Face cache.

Engines
- Sapient 0.6.9 (the release Elementum's Swift package uses): Metal and CPU,
  via `sapient bench-llm` (greedy, exact token counts, warm-up excluded).
- llama.cpp: Metal and CPU at 4 threads (this M2's performance-core count),
  via `llama-bench`.
- mlx-lm (optional): mlx-community/Qwen2.5-1.5B-Instruct-4bit. A different
  weights file (MLX 4-bit), shown for context only.

Method follows Sapient's docs/BENCHMARKS.md: same file, decode tokens per
second over N generated tokens, several runs, rounds interleaved across engines
so background load hits every engine alike; report medians.

    python3 run_engines.py --sapient /path/to/sapient --llama-dir /path/to/llama
"""
import argparse
import glob
import json
import os
import platform
import re
import shutil
import statistics as st
import subprocess
import time

HERE = os.path.dirname(os.path.abspath(__file__))
PROMPT = "Explain in detail how a bicycle stays upright when it is moving."
HUB = os.path.expanduser("~/.cache/huggingface/hub")
GGUF_GLOB = HUB + "/models--Qwen--Qwen2.5-1.5B-Instruct-GGUF/snapshots/*/qwen2.5-1.5b-instruct-q4_k_m.gguf"
MLX_REPO = "mlx-community/Qwen2.5-1.5B-Instruct-4bit"


def sh(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def machine():
    chip = sh(["sysctl", "-n", "machdep.cpu.brand_string"]).stdout.strip()
    mem = int(sh(["sysctl", "-n", "hw.memsize"]).stdout) // 2**30
    perf = sh(["sysctl", "-n", "hw.perflevel0.physicalcpu"]).stdout.strip()
    return dict(chip=chip, memory_gb=mem, performance_cores=perf,
                os=f"macOS {platform.mac_ver()[0]}")


def top_cpu():
    """The busiest processes, recorded so readers know the background load."""
    out = sh(["ps", "-Ao", "pcpu,comm", "-r"]).stdout.splitlines()[1:4]
    return [line.strip() for line in out]


def sapient(binary, backend, n, runs):
    r = sh([binary, "bench-llm", "qwen2.5-1.5b-q4", "-b", backend, "-p", PROMPT,
            "--max-tokens", str(n), "--runs", str(runs), "--warmup", "1", "--json"])
    d = json.loads(r.stdout[r.stdout.index("{"):])
    return dict(tps=[x["tps"] for x in d["runs"]], ttft_ms=[x["ttft_ms"] for x in d["runs"]],
                peak_rss_mb=d["summary"]["peak_rss_mb"], load_ms=d["load_time_ms"], raw=d)


def llama(bench, gguf, ngl, threads, n, runs):
    r = sh([bench, "-m", gguf, "-ngl", str(ngl), "-t", str(threads), "-p", "32",
            "-n", str(n), "-r", str(runs), "-o", "json"])
    rows = json.loads(r.stdout[r.stdout.index("["):])
    out = {}
    for x in rows:
        if x.get("n_gen", 0) > 0:
            out["tps"] = [round(v, 1) for v in x["samples_ts"]]
        if x.get("n_prompt", 0) > 0:
            out["prefill_tps"] = [round(v, 1) for v in x["samples_ts"]]
    out.update(build=rows[0].get("build_commit"), raw=rows)
    return out


def mlx(n, runs):
    tps, peak = [], []
    for i in range(runs + 1):
        r = sh(["uvx", "--from", "mlx-lm", "mlx_lm.generate", "--model", MLX_REPO,
                "--prompt", PROMPT, "--max-tokens", str(n), "--temp", "0"])
        txt = r.stdout + r.stderr
        if i == 0:
            continue  # first run downloads and warms up
        g = re.search(r"Generation:\s*(\d+) tokens,\s*([\d.]+) tokens-per-sec", txt)
        p = re.search(r"Peak memory:\s*([\d.]+) GB", txt)
        if g:
            tps.append(float(g.group(2)))
        if p:
            peak.append(float(p.group(1)))
    return dict(tps=tps, peak_gb=peak)


def median(xs):
    return round(st.median(xs), 1) if xs else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sapient", required=True)
    ap.add_argument("--llama-dir", required=True)
    ap.add_argument("--tokens", type=int, default=128)
    ap.add_argument("--runs", type=int, default=5)
    ap.add_argument("--rounds", type=int, default=2)
    ap.add_argument("--skip-mlx", action="store_true")
    a = ap.parse_args()

    gguf = glob.glob(GGUF_GLOB)[0]
    bench = os.path.join(a.llama_dir, "llama-bench")
    engines = {
        "Sapient Metal": lambda: sapient(a.sapient, "metal", a.tokens, a.runs),
        "llama.cpp Metal": lambda: llama(bench, gguf, 99, 4, a.tokens, a.runs),
        "Sapient CPU": lambda: sapient(a.sapient, "cpu", a.tokens, a.runs),
        "llama.cpp CPU 4t": lambda: llama(bench, gguf, 0, 4, a.tokens, a.runs),
    }
    if not a.skip_mlx and shutil.which("uvx"):
        engines["mlx-lm (MLX 4-bit, context)"] = lambda: mlx(a.tokens, a.runs)

    res = dict(date=time.strftime("%Y-%m-%d"), machine=machine(), model="Qwen2.5-1.5B-Instruct Q4_K_M",
               gguf=os.path.basename(gguf), prompt=PROMPT, tokens=a.tokens, runs=a.runs,
               rounds=a.rounds, sapient_version=sh([a.sapient, "--version"]).stdout.strip(),
               rounds_data=[])
    for rnd in range(a.rounds):
        rd = {"round": rnd + 1, "background_before": top_cpu(), "engines": {}}
        for name, fn in engines.items():
            print(f"round {rnd + 1}: {name} ...", flush=True)
            rd["engines"][name] = fn()
            time.sleep(5)  # let the GPU and CPU cool between engines
        res["rounds_data"].append(rd)

    summary = {}
    for name in engines:
        runs = [r["engines"][name] for r in res["rounds_data"]]
        tps = [t for r in runs for t in r.get("tps", [])]
        ttft = [t for r in runs for t in r.get("ttft_ms", [])]
        rss = [r["peak_rss_mb"] for r in runs if "peak_rss_mb" in r]
        summary[name] = dict(decode_tps_median=median(tps), decode_tps_min=min(tps) if tps else None,
                             decode_tps_max=max(tps) if tps else None,
                             ttft_ms_median=median(ttft), peak_rss_mb=max(rss) if rss else None,
                             samples=len(tps))
    res["summary"] = summary

    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    path = os.path.join(HERE, "results", f"engines-{res['date']}.json")
    with open(path, "w") as f:
        json.dump(res, f, indent=2)
    print(json.dumps(summary, indent=2))
    print("wrote", path)


if __name__ == "__main__":
    main()
