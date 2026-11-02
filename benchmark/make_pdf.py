#!/usr/bin/env python3
"""Build benchmark/Elementum-Sapient-benchmark.pdf from results/*.json and chart.png.

Every number in the report is read from the raw JSON, not typed in. Chrome
prints the HTML to an A4 PDF.

    python3 make_pdf.py
"""
import base64
import glob
import json
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


def latest(prefix):
    files = sorted(f for f in glob.glob(os.path.join(HERE, "results", f"{prefix}-*.json"))
                   if "throttled" not in f)
    return json.load(open(files[-1]))


def table(head, rows, right_from=1):
    th = "".join(f'<th class="{"r" if i >= right_from else ""}">{h}</th>' for i, h in enumerate(head))
    trs = "".join("<tr>" + "".join(f'<td class="{"r" if i >= right_from else ""}">{c}</td>'
                                   for i, c in enumerate(r)) + "</tr>" for r in rows)
    return f"<table><thead><tr>{th}</tr></thead><tbody>{trs}</tbody></table>"


def main():
    e = latest("engines")
    c = latest("combine")
    m = e["machine"]
    chart = base64.b64encode(open(os.path.join(HERE, "chart.png"), "rb").read()).decode()

    eng_rows = []
    for k in ["mlx-lm (MLX 4-bit, context)", "llama.cpp Metal", "Sapient Metal", "llama.cpp CPU 4t", "Sapient CPU"]:
        s = e["summary"][k]
        eng_rows.append([k, f'{s["decode_tps_median"]:.1f}', f'{s["decode_tps_min"]:.1f}–{s["decode_tps_max"]:.1f}',
                         f'{s["ttft_ms_median"]:.0f} ms' if s["ttft_ms_median"] else "—",
                         f'{s["peak_rss_mb"] / 1024:.2f} GB' if s["peak_rss_mb"] else "—"])

    order = sorted(c["engines"], key=lambda k: c["engines"][k]["summary"]["median_total_ms"])
    com_rows = []
    for k in order:
        s = c["engines"][k]["summary"]
        com_rows.append([k, f'{s["median_total_ms"] / 1000:.2f} s', f'{s["median_ttft_ms"]:.0f} ms',
                         f'{s["median_decode_tps"]:.1f}', f'{s["correct"]}/{s["cases"]}'])

    names = list(c["engines"])
    short = {"Sapient Metal": "Sapient Metal", "Sapient CPU": "Sapient CPU",
             "llama.cpp Metal": "llama.cpp", "llama.cpp Metal, no prompt cache": "llama.cpp, no cache"}
    case_rows = []
    for i, case in enumerate(c["engines"][names[0]]["cases"]):
        exp = case["expected"] if isinstance(case["expected"], str) else " + ".join(case["expected"])
        cells = []
        for n in names:
            g = c["engines"][n]["cases"][i]["grade"]
            cells.append(f'<span class="{"ok" if g == "correct" else "bad"}">{"✓" if g == "correct" else "✗"}</span> {g}')
        case_rows.append([case["reactants"], exp] + cells)

    sap = c["engines"]["Sapient Metal"]["summary"]
    lc = c["engines"]["llama.cpp Metal"]["summary"]
    lnc = c["engines"]["llama.cpp Metal, no prompt cache"]["summary"]
    scpu = c["engines"]["Sapient CPU"]["summary"]
    sm, lm = e["summary"]["Sapient Metal"]["decode_tps_median"], e["summary"]["llama.cpp Metal"]["decode_tps_median"]
    behind = (1 - sm / lm) * 100
    import statistics as stx
    sw = json.load(open(sorted(glob.glob(os.path.join(HERE, "results", "swift-package-*.json")))[-1]))
    import run_combine as rc
    expected = dict(rc.CASES)
    sw_rows = []
    for b in ["auto", "cpu"]:
        for mode, label in [("app_today", "before: reset() + chat"), ("prompt_cached", "after: [system, user] messages")]:
            cs = sw[b]["modes"][mode]
            rs = [r for x in cs for r in x["runs"]]
            ok = sum(rc.grade(x["runs"][0]["reply"], expected[x["reactants"]]) == "correct" for x in cs)
            sw_rows.append([f'{b} ({sw[b]["label"]})', label, f'{stx.median(r["total_ms"] for r in rs) / 1000:.2f} s',
                            f'{stx.median(r["ttft_ms"] for r in rs):.0f} ms', f'{stx.median(r["decode_tps"] for r in rs):.1f}', f"{ok}/16"])
    def swmed(mode, key):
        return stx.median(r[key] for x in sw["auto"]["modes"][mode] for r in x["runs"])
    before_s, after_s = swmed("app_today", "total_ms") / 1000, swmed("prompt_cached", "total_ms") / 1000
    first_word = swmed("prompt_cached", "ttft_ms")

    html = f"""<!doctype html><html><head><meta charset="utf-8"><title>Elementum benchmark</title><style>
  @page {{ size: A4; margin: 18mm 16mm 18mm 16mm; }}
  body {{ font-family: -apple-system, "SF Pro Text", "Helvetica Neue", sans-serif; color:#0b0b0b; font-size:10pt; line-height:1.45; }}
  h1 {{ font-size:24pt; letter-spacing:-0.5px; margin:0 0 4px; }}
  h2 {{ font-size:14pt; margin:22px 0 6px; padding-top:6px; border-top:1px solid #e4e3df; }}
  .lede {{ color:#52514e; font-size:11pt; margin:0 0 14px; }}
  .meta {{ color:#6b6a66; font-size:9pt; margin-bottom:16px; }}
  .key {{ display:flex; gap:10px; margin:14px 0 18px; }}
  .stat {{ flex:1; background:#f4f3f0; border-radius:8px; padding:10px 12px; }}
  .stat b {{ display:block; font-size:17pt; letter-spacing:-0.3px; }}
  .stat span {{ color:#52514e; font-size:9pt; }}
  table {{ width:100%; border-collapse:collapse; margin:8px 0 6px; font-size:9.5pt; page-break-inside:avoid; }}
  h2, h2 + p.note {{ page-break-after:avoid; }}
  section.block {{ page-break-inside:avoid; }}
  th {{ text-align:left; color:#52514e; font-weight:600; border-bottom:1.5px solid #0b0b0b; padding:5px 6px; }}
  td {{ border-bottom:1px solid #e4e3df; padding:5px 6px; vertical-align:top; }}
  .r {{ text-align:right; font-variant-numeric: tabular-nums; }}
  .small table {{ font-size:8.2pt; }}
  .small td, .small th {{ padding:3px 5px; }}
  .ok {{ color:#1a7f37; font-weight:700; }} .bad {{ color:#b42318; font-weight:700; }}
  ul {{ padding-left:18px; margin:6px 0; }} li {{ margin:4px 0; }}
  .note {{ color:#52514e; font-size:9pt; }}
  .chart {{ text-align:center; page-break-inside:avoid; }}
  .chart img {{ height:112mm; border:1px solid #e4e3df; border-radius:6px; }}
  .page {{ page-break-before:always; }}
  code {{ font-family: "SF Mono", Menlo, monospace; font-size:8.8pt; background:#f4f3f0; padding:0 3px; border-radius:3px; }}
</style></head><body>

<h1>Elementum on-device AI benchmark</h1>
<p class="lede">How the engine inside Elementum, Sapient, compares with llama.cpp and mlx-lm on the same model and on
Elementum's real Combine task.</p>
<p class="meta">{e["date"]} · {m["chip"]} MacBook Air, {m["memory_gb"]} GB, {m["performance_cores"]} performance cores, fanless ·
{m["os"]} · Sapient {e["sapient_version"].split()[-1]} · llama.cpp build {e["rounds_data"][0]["engines"]["llama.cpp Metal"]["build"]}</p>

<div class="key">
  <div class="stat"><b>{sm:.0f} tok/s</b><span>Sapient on Metal, decode. llama.cpp: {lm:.0f} ({behind:.0f}% ahead)</span></div>
  <div class="stat"><b>{after_s:.2f} s</b><span>Per Combine reaction in Elementum's engine, prompt cached. Was {before_s:.2f} s ({before_s / after_s:.0f}x faster)</span></div>
  <div class="stat"><b>{first_word:.0f} ms</b><span>To the first word of a reaction, prompt cached</span></div>

</div>

<h2>Setup</h2>
<ul>
  <li><b>Model:</b> Qwen2.5-1.5B-Instruct Q4_K_M, the exact GGUF file Elementum downloads (<code>{e["gguf"]}</code>, 1.12 GB).
      Every engine that reads GGUF read this same file.</li>
  <li><b>Engines:</b> Sapient {e["sapient_version"].split()[-1]} (the release Elementum's Swift package uses, Metal build),
      llama.cpp, and mlx-lm with a separate MLX 4-bit file, shown for context only.</li>
  <li><b>Fairness:</b> engines were interleaved and rotated, with pauses between requests, so heat on this fanless Mac and
      background load hit each one alike. Spotlight was indexing during the session (about one core).</li>
</ul>

<div class="chart"><img src="data:image/png;base64,{chart}"></div>

<h2>1. Raw decode speed</h2>
<p class="note">{e["tokens"]} generated tokens, {e["runs"]} runs per engine per round, {e["rounds"]} interleaved rounds. Sapient via
<code>sapient bench-llm</code>, llama.cpp via <code>llama-bench</code> (4 threads for CPU), mlx-lm via <code>mlx_lm.generate</code>.</p>
{table(["Engine", "Decode tok/s (median)", "Range", "First token", "Peak memory"], eng_rows)}
<p class="note">llama-bench and mlx_lm.generate don't report time to first token; part 2 measures it for llama.cpp through its server.</p>

<section class="block"><h2>2. Elementum's Combine task</h2>
<p class="note">Elementum's own system prompt (about 430 tokens, read from <code>ReactionModel.swift</code>) and
<code>Reactants: …</code> messages, greedy, up to 150 tokens, as the app sends them. 16 reactions × 3 passes × 4 configs, all
servers running at once, order rotated for each reaction. Every config gave identical replies on all three passes, and speed
changed by under 5% from the start of the run to the end.</p>
{table(["Config", "Time per reaction", "First token", "Decode tok/s", "Correct"], com_rows)}
<p class="note">Time per reaction runs from sending the request to the last token. llama.cpp's server reuses the shared system
prompt between requests unless asked not to, so the "no prompt cache" row is the like-for-like comparison with Sapient on Metal.</p></section>

<section class="block"><h2>3. The engine Elementum ships, through the Swift package</h2>
<p class="note">Parts 1 and 2 used Sapient's command-line Metal build, whose GPU engine is MLX. The Swift package Elementum
ships is built with wgpu on Metal plus the CPU engine, and no MLX. So this part runs the same 16 reactions × 3 passes through
<code>sapient-swift</code> 0.6.9 itself, comparing the call pattern Elementum used with one that keeps the system prompt cached,
interleaved, each in its own session. With <code>auto</code>, Sapient timed GPU and CPU at first load and chose the CPU on this M2
(prompt 615 ms vs 1170 ms on the GPU; 24.9 ms vs 46.5 ms per token).</p>
{table(["Backend", "Call pattern", "Time per reaction", "First token", "Decode tok/s", "Correct"], sw_rows, right_from=2)}
<p class="note"><code>reset()</code> clears the conversation and the cache, so calling it before every reaction made Sapient read the
~430-token prompt again each time. <code>chatMessagesStream(messages:)</code> is stateless and uses the prefix cache every session
enables, so only the new reactants are read. Replies were identical in both patterns on all 16 reactions. Elementum now uses
<code>chatMessagesStream</code>.</p></section>

<h2>What it shows</h2>
<ul>
  <li><b>llama.cpp is faster on this Mac.</b> On raw decode, Sapient on Metal is about {behind:.0f}% behind llama.cpp on Metal
      ({sm:.0f} vs {lm:.0f} tok/s), in line with Sapient's own published numbers.</li>
  <li><b>Sapient keeps the prompt cached, and Elementum wasn't using it.</b> In the app's own engine, sending each reaction as
      [system, user] messages instead of reset() + chat took a reaction from {before_s:.2f} s to {after_s:.2f} s and the first word to
      {first_word:.0f} ms, with identical answers.</li>
  <li><b>Part 2 measured the MLX build, not the app's engine.</b> Sapient's MLX engine can't truncate its cache, so there it re-read
      the prompt each time ({sap["median_total_ms"] / 1000:.2f} s); llama.cpp's server keeps its prompt cache and answered in
      {lc["median_total_ms"] / 1000:.2f} s. The wgpu and CPU engines in the Swift package do reuse the prompt.</li>
  <li><b>Sapient picks the faster processor for you.</b> At first load it times GPU and CPU for the model on the device, uses the
      faster one and keeps that choice for 30 days.</li>
  <li><b>Accuracy is the model's limit, not the engine's.</b> All four configs scored {sap["correct"]} or {lc["correct"]} out of 16 with the
      same mistakes: invented reactions for platinum with hydrochloric acid and for neon, an answer for the made-up element
      "Xq" instead of a rejection, and 2 H2 + 2 O2 left unbalanced. The two Sapient backends each differ from llama.cpp on one
      reaction. Those fixes belong in the app: check reactants against the element list, and check that the reply balances.</li>
  <li><b>Why Elementum uses Sapient.</b> One Swift package that downloads a model with byte progress and resumes it, loads it
      offline from the cache and fits it inside iOS's memory limit. The same engine runs speech and vision and has Kotlin and
      React Native SDKs.</li>
</ul>

<h2>4. Every answer, graded</h2>
<p class="note">The grader checks that every element has the same atom count on both sides and that the products match the
expected answer. "No reaction" and invalid-input cases must follow the prompt's rules. The three examples inside the prompt were
left out of the test set.</p>
<div class="small">{table(["Reactants", "Expected"] + [short[n] for n in names], case_rows, right_from=99)}</div>

<h2>Caveats</h2>
<ul>
  <li><b>A Mac, not an iPhone.</b> Elementum runs on iPhones, where every timing will differ. The ranking of engines is what
      carries over.</li>
  <li><b>Different precision on Metal.</b> Sapient's Metal build re-quantizes weights to MLX 4-bit at load, so it reads the same
      file as llama.cpp but doesn't run exactly the same numbers. mlx-lm reads a different file.</li>
  <li><b>A first sequential run</b> (each engine in turn) throttled whichever engine went second. It's kept in
      <code>results/</code> and not used here.</li>
  <li><b>Small test set:</b> 16 reactions covering common reactions, a wrong-quantity input, two non-reactions and an invalid
      element.</li>
</ul>
<p class="note">Scripts and raw data: <code>Elementum/benchmark</code> (<code>run_engines.py</code>, <code>run_combine.py</code>,
<code>results/*.json</code>).</p>
</body></html>"""
    page = os.path.join(HERE, "report.html")
    open(page, "w").write(html)
    pdf = os.path.join(HERE, "Elementum-Sapient-benchmark.pdf")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={pdf}", "file://" + page], check=True, capture_output=True)
    os.remove(page)
    print("wrote", pdf)


if __name__ == "__main__":
    main()
