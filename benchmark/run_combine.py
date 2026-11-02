#!/usr/bin/env python3
"""Combine benchmark: Elementum's real reaction task, Sapient vs llama.cpp.

All servers run at once and each reaction is sent to every config in a rotating
order with a short cool-down, so thermal throttling (this is a fanless MacBook
Air) and background load hit every config alike. An earlier sequential run
throttled whichever engine went second; it is kept in results/ for reference.

Sends Elementum's exact system prompt (from Elementum/Components/ReactionModel.swift)
and "Reactants: ..." user messages to two OpenAI-compatible servers running the
same GGUF file (Qwen2.5-1.5B-Instruct Q4_K_M), greedy, max 150 tokens, as the
app does. For each reply it measures time to first token, total time and
tokens, and grades the chemistry automatically:

- correct: the equation balances and has the expected products,
- for "no reaction" and invalid-input cases, the reply follows the prompt's rule.

    python3 run_combine.py --sapient /path/to/sapient --llama-dir /path/to/llama
"""
import argparse
import glob
import json
import os
import re
import statistics as st
import subprocess
import time
import urllib.request
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
SWIFT = os.path.join(HERE, "..", "Elementum", "Components", "ReactionModel.swift")
HUB = os.path.expanduser("~/.cache/huggingface/hub")
GGUF_GLOB = HUB + "/models--Qwen--Qwen2.5-1.5B-Instruct-GGUF/snapshots/*/qwen2.5-1.5b-instruct-q4_k_m.gguf"
MAX_TOKENS = 150

# (reactants, expected) - expected is products as formulas, or "none" / "invalid".
# The three worked examples in the prompt (H + O, Na + Cl2, Au + H2O) are left out.
CASES = [
    ("Mg + O2", ["MgO"]),
    ("Fe + O2", ["Fe2O3"]),
    ("CH4 + O2", ["CO2", "H2O"]),
    ("Zn + HCl", ["ZnCl2", "H2"]),
    ("NaOH + HCl", ["NaCl", "H2O"]),
    ("Na + H2O", ["NaOH", "H2"]),
    ("Cu + AgNO3", ["Cu(NO3)2", "Ag"]),
    ("C + O2", ["CO2"]),
    ("N2 + H2", ["NH3"]),
    ("Al + O2", ["Al2O3"]),
    ("Ca + H2O", ["Ca(OH)2", "H2"]),
    ("K + Cl2", ["KCl"]),
    ("2 H2 + 2 O2", ["H2O"]),
    ("Pt + HCl", "none"),
    ("Ne + O2", "none"),
    ("Xq + O2", "invalid"),
]


def system_prompt():
    """Elementum's prompt, read from the Swift source so the two never drift apart."""
    src = open(SWIFT).read()
    body = re.search(r'private let systemPrompt = """\n(.*?)\n\s*"""', src, re.S).group(1)
    lines = [ln[8:] if ln.startswith("        ") else ln.strip() for ln in body.split("\n")]
    text = "\n".join(lines)
    return text.replace("\\\n", "")  # Swift line continuations


# ---------------------------------------------------------------- chemistry

def atoms(formula):
    """Atom counts for a formula like Ca(OH)2 or 2H2O (coefficient included)."""
    formula = re.sub(r"\^[\d]*[+-]", "", formula)          # ionic charges
    formula = re.sub(r"\((aq|s|l|g)\)", "", formula)        # states
    m = re.match(r"^(\d*)(.*)$", formula.strip())
    coef = int(m.group(1) or 1)
    tokens = re.findall(r"[A-Z][a-z]?|\d+|\(|\)", m.group(2))
    stack = [Counter()]
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t == "(":
            stack.append(Counter())
        elif t == ")":
            group = stack.pop()
            mult = 1
            if i + 1 < len(tokens) and tokens[i + 1].isdigit():
                mult = int(tokens[i + 1])
                i += 1
            for k, v in group.items():
                stack[-1][k] += v * mult
        elif t[0].isalpha():
            n = 1
            if i + 1 < len(tokens) and tokens[i + 1].isdigit():
                n = int(tokens[i + 1])
                i += 1
            stack[-1][t] += n
        i += 1
    return Counter({k: v * coef for k, v in stack[0].items()})


def side(text):
    total = Counter()
    species = []
    for part in re.split(r"\s\+\s", text.strip()):
        part = part.strip().replace(" ", "")
        if not part:
            continue
        total += atoms(part)
        species.append(re.sub(r"^\d+", "", re.sub(r"\((aq|s|l|g)\)", "", part)))
    return total, species


def grade(reply, expected):
    eq = re.search(r"EQUATION:\s*(.+)", reply)
    if expected == "invalid":
        return "correct" if "correct the reactants" in reply.lower() else "wrong"
    if not eq:
        return "no equation line"
    eq = eq.group(1).strip()
    if expected == "none":
        return "correct" if "no reaction" in eq.lower() else "invented a reaction"
    if "no reaction" in eq.lower():
        return "missed the reaction"
    halves = re.split(r"\s*(?:→|->|=|⟶)\s*", eq, maxsplit=1)
    if len(halves) != 2:
        return "unparseable"
    try:
        left, _ = side(halves[0])
        right, products = side(halves[1])
    except Exception:
        return "unparseable"
    if left != right:
        return "unbalanced"
    if sorted(set(products)) != sorted(set(expected)):
        return "wrong products"
    return "correct"


# ---------------------------------------------------------------- engines

def wait_ready(url, timeout=600):
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            urllib.request.urlopen(url, timeout=2)
            return True
        except Exception:
            time.sleep(1)
    return False


def chat(base, model, system, user, extra=None):
    payload = dict(model=model, temperature=0, max_tokens=MAX_TOKENS, stream=True,
                   stream_options={"include_usage": True},
                   messages=[dict(role="system", content=system), dict(role="user", content=user)])
    payload.update(extra or {})
    body = json.dumps(payload).encode()
    req = urllib.request.Request(base + "/v1/chat/completions", data=body,
                                 headers={"Content-Type": "application/json"})
    t0 = time.perf_counter()
    first = None
    text = []
    chunks = 0
    usage = None
    with urllib.request.urlopen(req, timeout=600) as resp:
        for raw in resp:
            line = raw.decode().strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            j = json.loads(data)
            if j.get("usage"):
                usage = j["usage"]
            for choice in j.get("choices", []):
                piece = (choice.get("delta") or {}).get("content")
                if piece:
                    if first is None:
                        first = time.perf_counter() - t0
                    text.append(piece)
                    chunks += 1
    total = time.perf_counter() - t0
    tokens = (usage or {}).get("completion_tokens") or chunks
    decode = tokens / (total - first) if first and total > first and tokens > 1 else None
    return dict(at=round(time.time(), 1), reply="".join(text).strip(), ttft_ms=round(first * 1000) if first else None,
                total_ms=round(total * 1000), tokens=tokens,
                tokens_from="usage" if usage else "stream chunks",
                decode_tps=round(decode, 1) if decode else None)


def stop(proc):
    proc.terminate()
    try:
        proc.wait(timeout=20)
    except subprocess.TimeoutExpired:
        proc.kill()


def summarise(results):
    ok = sum(r["grade"] == "correct" for r in results)
    return dict(correct=ok, cases=len(results), accuracy=round(ok / len(results), 3),
                median_ttft_ms=st.median([r["ttft_ms"] for r in results]),
                median_total_ms=st.median([r["total_ms"] for r in results]),
                median_decode_tps=round(st.median([r["decode_tps"] for r in results]), 1),
                grades=dict(Counter(r["grade"] for r in results)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sapient", required=True)
    ap.add_argument("--llama-dir", required=True)
    ap.add_argument("--passes", type=int, default=3, help="requests per case and config")
    ap.add_argument("--cooldown", type=float, default=2.0, help="seconds between requests")
    a = ap.parse_args()
    gguf = glob.glob(GGUF_GLOB)[0]
    system = system_prompt()
    log = open(os.path.join("/tmp", "combine-servers.log"), "w")

    # All servers run at once and requests rotate between configs, so heat on a
    # fanless Mac (and any background load) lands on every config alike.
    servers = [
        subprocess.Popen([a.sapient, "serve", "--port", "11435", "-b", "metal"], stdout=log, stderr=log),
        subprocess.Popen([a.sapient, "serve", "--port", "11436", "-b", "cpu"], stdout=log, stderr=log),
        subprocess.Popen([os.path.join(a.llama_dir, "llama-server"), "-m", gguf, "-ngl", "99",
                          "-c", "2048", "--port", "8081"], stdout=log, stderr=log),
    ]
    configs = {
        "Sapient Metal": dict(base="http://127.0.0.1:11435", model="qwen2.5-1.5b-q4", extra=None),
        "Sapient CPU": dict(base="http://127.0.0.1:11436", model="qwen2.5-1.5b-q4", extra=None),
        "llama.cpp Metal": dict(base="http://127.0.0.1:8081", model="qwen2.5-1.5b", extra=None),
        "llama.cpp Metal, no prompt cache": dict(base="http://127.0.0.1:8081", model="qwen2.5-1.5b",
                                                 extra={"cache_prompt": False}),
    }
    try:
        for name, c in configs.items():
            if not wait_ready(c["base"] + "/v1/models"):
                raise RuntimeError(f"{name} did not start")
            chat(c["base"], c["model"], system, "Reactants: H + O", c["extra"])   # warm-up: loads the model
        names = list(configs)
        runs = {n: {r: [] for r, _ in CASES} for n in names}
        step = 0
        for p in range(a.passes):
            for reactants, expected in CASES:
                order = names[step % len(names):] + names[:step % len(names)]   # rotate who goes first
                step += 1
                for n in order:
                    c = configs[n]
                    runs[n][reactants].append(chat(c["base"], c["model"], system,
                                                   f"Reactants: {reactants}", c["extra"]))
                    time.sleep(a.cooldown)
                print(f"pass {p + 1} {reactants:14} " + "  ".join(
                    f"{n.split(',')[0][:15]}: {runs[n][reactants][-1]['total_ms']}ms" for n in names), flush=True)
    finally:
        for proc in servers:
            stop(proc)

    out = dict(date=time.strftime("%Y-%m-%d"), model="Qwen2.5-1.5B-Instruct Q4_K_M (same GGUF file)",
               settings=dict(temperature=0, max_tokens=MAX_TOKENS, passes=a.passes,
                             cooldown_s=a.cooldown, order="rotated per case, all servers running"),
               system_prompt=system, engines={})
    for n in names:
        cases = []
        for reactants, expected in CASES:
            rs = runs[n][reactants]
            first = rs[0]
            cases.append(dict(
                reactants=reactants, expected=expected, reply=first["reply"],
                grade=grade(first["reply"], expected),
                deterministic=all(r["reply"] == first["reply"] for r in rs),
                ttft_ms=st.median([r["ttft_ms"] for r in rs if r["ttft_ms"]]),
                total_ms=st.median([r["total_ms"] for r in rs]),
                tokens=first["tokens"], tokens_from=first["tokens_from"],
                decode_tps=st.median([r["decode_tps"] for r in rs if r["decode_tps"]] or [0]),
                runs=rs))
        out["engines"][n] = dict(summary=summarise(cases), cases=cases)

    path = os.path.join(HERE, "results", f"combine-{out['date']}.json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(json.dumps({k: v["summary"] for k, v in out["engines"].items()}, indent=2))
    print("wrote", path)


if __name__ == "__main__":
    main()
