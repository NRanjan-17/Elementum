// Sapient through its Swift package (the engine Elementum ships: wgpu on Metal, or CPU).
// Compares Elementum's current call pattern with one that keeps the system prompt cached.
import Foundation
import Sapient

let systemPrompt = """
        You are a careful chemistry tutor inside an app where students experiment by combining elements and compounds. \
        You are given a list of reactants joined by " + ". Quantities such as "2 H2" are optional and may be unbalanced.

        Reply with exactly two lines and nothing else:
        EQUATION: <balanced chemical equation with every product and by-product, using → between sides>
        DESCRIPTION: <one sentence naming the reaction type and what is observed>

        Rules:
        - Only describe reactions that really happen under common conditions. Never invent products.
        - If the substances do not react, write "EQUATION: No reaction" and explain why in DESCRIPTION.
        - If an entry is not a real element, compound or formula, reply only: Correct the reactants
        - If only the quantities are off, balance the equation using the correct ratio and say so.
        - Elements that exist as molecules are written in molecular form: H2, N2, O2, F2, Cl2, Br2, I2. \
        Other elements are written as single atoms (Na, Fe, C).
        - Balance with the smallest whole-number coefficients and make sure every element has the same atom count on both sides.
        - Write formulas in plain ASCII (H2O, not subscripts). Write ionic charges with ^ (Fe^3+, SO4^2-).
        - Plain text only: no markdown, no extra commentary.

        Examples:
        Reactants: H + O
        EQUATION: 2H2 + O2 → 2H2O
        DESCRIPTION: A combination (synthesis) reaction in which hydrogen burns in oxygen to form water.

        Reactants: Na + Cl2
        EQUATION: 2Na + Cl2 → 2NaCl
        DESCRIPTION: A synthesis reaction in which sodium and chlorine form sodium chloride, releasing heat and bright light.

        Reactants: Au + H2O
        EQUATION: No reaction
        DESCRIPTION: Gold is unreactive and does not react with water.
        """

let reactants = ["Mg + O2", "Fe + O2", "CH4 + O2", "Zn + HCl", "NaOH + HCl", "Na + H2O",
                 "Cu + AgNO3", "C + O2", "N2 + H2", "Al + O2", "Ca + H2O", "K + Cl2",
                 "2 H2 + 2 O2", "Pt + HCl", "Ne + O2", "Xq + O2"]
let passes = 3

final class Collector: TokenListener, @unchecked Sendable {
    var first: ContinuousClock.Instant?
    var count = 0
    func onToken(token: String) -> Bool {
        if first == nil, !token.isEmpty { first = .now }
        count += 1
        return true
    }
}
func ms(_ d: Duration) -> Double { Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15 }

func timed(_ body: (Collector) async throws -> String) async throws -> [String: Any] {
    let c = Collector()
    let t0 = ContinuousClock.now
    let reply = try await body(c)
    let total = ms(ContinuousClock.now - t0)
    let ttft = c.first.map { ms($0 - t0) } ?? total
    let decode = c.count > 1 && total > ttft ? Double(c.count - 1) / ((total - ttft) / 1000) : 0
    return ["reply": reply.trimmingCharacters(in: .whitespacesAndNewlines), "ttft_ms": ttft,
            "total_ms": total, "tokens": c.count, "decode_tps": decode]
}

setCacheDir(path: NSHomeDirectory() + "/.cache/huggingface")
let alias = "qwen2.5-1.5b-q4"
var out: [String: Any] = ["sapient": Sapient.version(), "model": alias,
                          "date": ISO8601DateFormatter().string(from: .now)]
for backend in CommandLine.arguments.dropFirst().isEmpty ? ["auto", "cpu"] : Array(CommandLine.arguments.dropFirst()) {
    let opts = GenerationOptions(maxTokens: 150, temperature: nil, systemPrompt: systemPrompt,
                                 backend: backend, contextLength: 2048)
    let today = try await loadSession(model: alias, options: opts)    // reset() + chat, as Elementum does now
    let cached = try await loadSession(model: alias, options: opts)   // [system, user] messages, prompt cached
    print("backend \(backend): \(today.backendLabel())")
    let msgs = { (r: String) in [Message(role: "system", content: systemPrompt), Message(role: "user", content: "Reactants: \(r)")] }
    _ = try await today.chatAsync(userMessage: "Reactants: H + O")
    _ = try await cached.chatMessagesStream(messages: msgs("H + O"), listener: Collector())
    var modes: [String: [[String: Any]]] = ["app_today": [], "prompt_cached": []]
    for (i, r) in reactants.enumerated() {
        var a: [[String: Any]] = [], b: [[String: Any]] = []
        for p in 0..<passes {
            let first = (i + p) % 2 == 0   // alternate which mode goes first
            for mode in first ? ["app_today", "prompt_cached"] : ["prompt_cached", "app_today"] {
                if mode == "app_today" {
                    a.append(try await timed { c in today.reset(); return try await today.chatStreamAsync(userMessage: "Reactants: \(r)", listener: c) })
                } else {
                    b.append(try await timed { c in try await cached.chatMessagesStream(messages: msgs(r), listener: c) })
                }
                try await Task.sleep(for: .seconds(1))
            }
        }
        modes["app_today"]!.append(["reactants": r, "runs": a])
        modes["prompt_cached"]!.append(["reactants": r, "runs": b])
        print("  \(r.padding(toLength: 13, withPad: " ", startingAt: 0)) today \(Int(a[0]["total_ms"] as! Double)) ms   cached \(Int(b[0]["total_ms"] as! Double)) ms")
    }
    out[backend] = ["label": today.backendLabel(), "modes": modes]
}
let path = CommandLine.arguments.count > 0 ? FileManager.default.currentDirectoryPath + "/swift-results.json" : ""
try JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: path))
print("wrote \(path)")
