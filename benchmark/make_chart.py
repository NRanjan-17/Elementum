#!/usr/bin/env python3
"""Draw benchmark/chart.png (1080x1350, for the LinkedIn post) from results/*.json.

Panels, horizontal bars, one axis each:
  1. Elementum's Combine task through Sapient's Swift package, before and after keeping
     the system prompt cached (swift-package-*.json, from swift/bench.swift)
  2. decode speed against other engines (engines-*.json, from run_engines.py)
  3. time to first word with the prompt cached, as a stat
Colour marks the engine family: Sapient blue, llama.cpp orange, mlx-lm aqua (validated
with the dataviz skill's checker; aqua is under 3:1 on the surface, so every bar carries a
direct value label). The "before" bar is neutral grey: it is a call pattern, not an engine.

    python3 make_chart.py
"""
import glob
import json
import os
import statistics as st
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
COLOR = {"Sapient": "#2a78d6", "llama.cpp": "#eb6834", "mlx-lm": "#1baf7a"}
BEFORE = "#a3a29d"


def latest(prefix):
    files = sorted(f for f in glob.glob(os.path.join(HERE, "results", f"{prefix}-*.json"))
                   if "throttled" not in f)
    return json.load(open(files[-1]))


def colour(label):
    if "before" in label.lower():
        return BEFORE
    return next(c for k, c in COLOR.items() if label.startswith(k))


def panel(title, subtitle, rows, unit, fmt, note):
    top = max(v for _, v in rows)
    bars = "".join(f'''
      <div class="row">
        <div class="label">{label}</div>
        <div class="track"><div class="bar" style="width:{value / top * 100:.1f}%;background:{colour(label)}"></div>
          <span class="value">{fmt(value)} {unit}</span></div>
      </div>''' for label, value in rows)
    return f'''
    <section>
      <h2>{title}</h2>
      <p class="sub">{subtitle}</p>
      {bars}
      <p class="note">{note}</p>
    </section>'''


def summary():
    eng = latest("engines")
    sw = latest("swift-package")
    com = latest("combine")

    def med(mode, key):
        return st.median(r[key] for c in sw["auto"]["modes"][mode] for r in c["runs"])

    names = {"Sapient Metal": "Sapient · Metal", "Sapient CPU": "Sapient · CPU",
             "llama.cpp Metal": "llama.cpp · Metal", "llama.cpp CPU 4t": "llama.cpp · CPU",
             "mlx-lm (MLX 4-bit, context)": "mlx-lm · Metal*"}
    speed = sorted(((names[k], v["decode_tps_median"]) for k, v in eng["summary"].items()), key=lambda r: -r[1])
    before, after = med("app_today", "total_ms") / 1000, med("prompt_cached", "total_ms") / 1000
    scores = sorted({f'{v["summary"]["correct"]}/{v["summary"]["cases"]}' for v in com["engines"].values()})
    return dict(eng=eng, sw=sw, speed=speed, before=before, after=after, speedup=before / after,
                first_word=med("prompt_cached", "ttft_ms"), first_word_before=med("app_today", "ttft_ms"),
                accuracy=" or ".join(scores))


def main():
    s = summary()
    m = s["eng"]["machine"]
    combine = [("Sapient · before, reset each time", s["before"]), ("Sapient · after, prompt cached", s["after"])]
    html = f'''<!doctype html><html><head><meta charset="utf-8"><style>
  body {{ margin:0; width:1080px; height:1350px; background:#fcfcfb; color:#0b0b0b;
         font-family:-apple-system,"SF Pro Display","Helvetica Neue",sans-serif; }}
  .wrap {{ padding:68px 80px; box-sizing:border-box; height:100%; display:flex; flex-direction:column; }}
  h1 {{ font-size:48px; letter-spacing:-1px; margin:0 0 10px; }}
  .lede {{ font-size:23px; color:#52514e; margin:0 0 30px; line-height:1.35; }}
  section {{ margin-bottom:40px; }}
  h2 {{ font-size:28px; margin:0 0 4px; }}
  .sub {{ font-size:19px; color:#52514e; margin:0 0 18px; line-height:1.35; }}
  .row {{ display:flex; align-items:center; margin:12px 0; }}
  .label {{ width:360px; font-size:21px; color:#0b0b0b; }}
  .track {{ flex:1; display:flex; align-items:center; gap:14px; }}
  .bar {{ height:30px; border-radius:0 4px 4px 0; }}
  .value {{ font-size:21px; font-weight:600; color:#0b0b0b; white-space:nowrap; font-variant-numeric:tabular-nums; }}
  .note {{ font-size:16px; color:#6b6a66; margin:12px 0 0; line-height:1.4; }}
  .legend {{ display:flex; gap:26px; font-size:19px; color:#52514e; margin:0 0 28px; flex-wrap:wrap; }}
  .key {{ display:inline-block; width:14px; height:14px; border-radius:3px; margin-right:8px; vertical-align:-1px; }}
  .stat {{ font-size:28px; font-weight:700; margin:0 0 4px; }}
  footer {{ margin-top:auto; font-size:16px; color:#6b6a66; line-height:1.45; border-top:1px solid #e4e3df; padding-top:16px; }}
</style></head><body><div class="wrap">
  <h1>Sapient inside Elementum</h1>
  <p class="lede">The Rust engine that runs Elementum's chemistry model on device. Qwen2.5-1.5B-Instruct, 4-bit, the same
  file the app downloads, on an {m["chip"]} MacBook Air ({m["memory_gb"]} GB).</p>
  <div class="legend">{''.join(f'<span><span class="key" style="background:{c}"></span>{k}</span>' for k, c in COLOR.items())}<span><span class="key" style="background:{BEFORE}"></span>before the fix</span></div>
  {panel(f"One API change, {s['speedup']:.0f}x faster", "Elementum's Combine task through Sapient's Swift package, the engine the app ships. Seconds per reaction, lower is better.",
         combine, "s", lambda v: f"{v:.2f}",
         "Before: reset() then chat, so the ~430-token system prompt was read again for every reaction. After: each reaction is sent as [system, user] messages and Sapient keeps the prompt in its cache. All 16 answers identical.")}
  {panel("Decode speed against other engines", "Tokens per second, higher is better. Median of 10 runs, 128 tokens.", s["speed"], "tok/s",
         lambda v: f"{v:.0f}", "* mlx-lm reads a different 4-bit file (MLX), shown for context. llama.cpp CPU uses the 4 performance cores.")}
  <section>
    <p class="stat">{s["first_word"]:.0f} ms to the first word</p>
    <p class="sub">With the prompt cached, Sapient starts answering a reaction in {s["first_word"]:.0f} ms (it was {s["first_word_before"] / 1000:.1f} s).
    Accuracy is the model's, not the engine's: {s["accuracy"]} on every engine.</p>
  </section>
  <footer>Sapient {s["sw"]["sapient"]} · llama.cpp build {s["eng"]["rounds_data"][0]["engines"]["llama.cpp Metal"]["build"]} · {m["os"]} · {s["eng"]["date"]}.
  Runs were interleaved so heat and background load hit each one alike. Mac numbers, not iPhone. Scripts and raw results: Elementum/benchmark.</footer>
</div></body></html>'''
    page = os.path.join(HERE, "chart.html")
    open(page, "w").write(html)
    png = os.path.join(HERE, "chart.png")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--window-size=1080,1350", f"--screenshot={png}", "file://" + page],
                   check=True, capture_output=True)
    print("wrote", png)


if __name__ == "__main__":
    main()
