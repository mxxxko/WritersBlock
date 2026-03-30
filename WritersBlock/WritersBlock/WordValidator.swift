import Foundation

struct WordValidator: Sendable {
    nonisolated static let shared = WordValidator()

    private let wordSet: Set<String>
    // Pre-converted to [Character] arrays — avoids per-call Array(word) allocation
    private let wordChars: [Int: [[Character]]]
    // [length][position][char] → indices into wordChars[length]
    private let posIndex: [Int: [Int: [Character: [Int]]]]

    nonisolated private init() {
        guard let url = Bundle.main.url(forResource: "wordlist", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            wordSet = []
            wordChars = [:]
            posIndex = [:]
            return
        }

        let parsed = content.components(separatedBy: .newlines)
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.allSatisfy(\.isLetter) }

        let unique = Array(Set(parsed))
        wordSet = Set(unique)

        // Group by length and pre-convert to [Character]
        var byLength: [Int: [[Character]]] = [:]
        for word in unique {
            byLength[word.count, default: []].append(Array(word))
        }
        wordChars = byLength

        // Build positional index
        var idx: [Int: [Int: [Character: [Int]]]] = [:]
        for (len, words) in byLength {
            var posIdx: [Int: [Character: [Int]]] = [:]
            for (wordIdx, chars) in words.enumerated() {
                for (pos, ch) in chars.enumerated() {
                    posIdx[pos, default: [:]][ch, default: []].append(wordIdx)
                }
            }
            idx[len] = posIdx
        }
        posIndex = idx
    }

    nonisolated func isValid(_ word: String) -> Bool {
        wordSet.contains(word.lowercased())
    }

    /// True iff at least one word of `length` matches `pattern`. O(k) where k = smallest index bucket.
    nonisolated func hasWords(ofLength length: Int, matching pattern: [Character?]) -> Bool {
        guard let chars = wordChars[length], let posIdx = posIndex[length] else { return false }
        let constrained = constrain(pattern)
        if constrained.isEmpty { return !chars.isEmpty }
        let best = smallest(constrained, in: posIdx)
        guard let seeds = posIdx[best.pos]?[best.ch] else { return false }
        return seeds.contains { i in constrained.allSatisfy { chars[i][$0.pos] == $0.ch } }
    }

    /// Returns up to `maxCount` random words of `length` matching `pattern`.
    nonisolated func sampleWords(
        ofLength length: Int,
        matching pattern: [Character?],
        maxCount: Int,
        using rng: inout some RandomNumberGenerator
    ) -> [String] {
        guard let chars = wordChars[length], let posIdx = posIndex[length] else { return [] }
        let constrained = constrain(pattern)

        if constrained.isEmpty {
            // No constraints — pick random indices without a full shuffle
            if chars.count <= maxCount { return chars.shuffled(using: &rng).map { String($0) } }
            var seen = Set<Int>(); var result: [Int] = []; result.reserveCapacity(maxCount)
            while result.count < maxCount {
                let i = Int.random(in: 0..<chars.count, using: &rng)
                if seen.insert(i).inserted { result.append(i) }
            }
            return result.map { String(chars[$0]) }
        }

        let best = smallest(constrained, in: posIdx)
        guard let seeds = posIdx[best.pos]?[best.ch] else { return [] }
        var matching = seeds.filter { i in constrained.allSatisfy { chars[i][$0.pos] == $0.ch } }
        if matching.isEmpty { return [] }
        let count = min(maxCount, matching.count)
        // Partial Fisher-Yates to pick `count` without shuffling the whole array
        for i in 0..<count {
            let j = i + Int.random(in: 0..<(matching.count - i), using: &rng)
            matching.swapAt(i, j)
        }
        return matching.prefix(count).map { String(chars[$0]) }
    }

    // MARK: - Helpers

    private typealias Constraint = (pos: Int, ch: Character)

    nonisolated private func constrain(_ pattern: [Character?]) -> [Constraint] {
        pattern.enumerated().compactMap { pos, ch in ch.map { (pos, $0) } }
    }

    nonisolated private func smallest(_ cs: [Constraint], in posIdx: [Int: [Character: [Int]]]) -> Constraint {
        cs.min(by: { posIdx[$0.pos]?[$0.ch]?.count ?? 0 < posIdx[$1.pos]?[$1.ch]?.count ?? 0 })!
    }
}
