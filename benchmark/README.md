# benchmark

Benchmarks of Elementum's on-device model across inference engines.

- `Elementum-Sapient-benchmark.pdf`: the full report (4 pages), kept out of git; rebuild it with `python3 make_pdf.py`.
- `RESULTS.md`: the same results, method and caveats as Markdown.
- `chart.png`: the results as an image, sized for LinkedIn (1080 × 1350).
- `results/`: raw JSON from every run.
- `swift/`: the Swift package harness (`swift run -c release bench`), which runs Sapient through `sapient-swift`, the engine Elementum ships.

## Run it again

You need the two engines' release binaries (nothing is installed system-wide):

```sh
# Sapient (the release Elementum's Swift package uses)
curl -L -o sapient.tgz https://github.com/openhorizon-labs/sapient-release/releases/download/v0.6.9/sapient-aarch64-apple-darwin-metal.tar.gz
mkdir sapient && tar -xzf sapient.tgz -C sapient

# llama.cpp
curl -L -o llama.tgz https://github.com/ggml-org/llama.cpp/releases/download/b12047/llama-b12047-bin-macos-arm64.tar.gz
mkdir llama && tar -xzf llama.tgz -C llama
```

Then, from this folder:

```sh
python3 run_engines.py --sapient sapient/sapient --llama-dir llama/llama-b12047   # ~10 min
python3 run_combine.py --sapient sapient/sapient --llama-dir llama/llama-b12047   # ~15 min
python3 make_chart.py
python3 make_pdf.py
```

`run_engines.py` downloads the model through Sapient on first run (1.1 GB), and llama.cpp reads the same file from
the Hugging Face cache. mlx-lm runs through `uvx` if it's installed (`--skip-mlx` to leave it out). The scripts use
only Python's standard library; `make_chart.py` and `make_pdf.py` need Google Chrome to render the PNG and PDF.

Close other heavy apps first and keep the Mac on power. On a fanless Mac, give it a minute to cool between runs.
