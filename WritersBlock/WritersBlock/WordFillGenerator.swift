import Foundation

struct WordFillGenerator {
    let validator: WordValidator
    private var iterations = 0
    private let maxIterations = 12_000
    private let maxCandidatesPerSlot = 60
    private var usedWords: Set<String> = []

    nonisolated init(validator: WordValidator) {
        self.validator = validator
    }

    /// Fills the grid with valid words for every slot using backtracking with forward checking.
    /// Returns nil if no solution is found within the iteration limit.
    nonisolated mutating func fill(
        gridSize: Int,
        blacks: Set<GridCoordinate>,
        slots: [WordSlot],
        using rng: inout some RandomNumberGenerator
    ) -> [[Character]]? {
        var grid = Array(repeating: Array(repeating: Character(" "), count: gridSize), count: gridSize)

        // Longest-first = most-constrained-first.
        let ordered = slots.sorted { $0.length > $1.length }

        // Feasibility pre-check: if any slot has zero candidates on an empty grid, bail immediately.
        for slot in ordered {
            if !validator.hasWords(ofLength: slot.length, matching: Array(repeating: nil, count: slot.length)) {
                return nil
            }
        }

        // Precompute which later slots each slot intersects (shares a cell with).
        // forwardCheck uses this to avoid scanning all remaining slots on every call.
        var intersections = [[Int]](repeating: [], count: ordered.count)
        for i in ordered.indices {
            let cellSet = Set(ordered[i].cells)
            intersections[i] = ordered.indices.filter { j in
                j > i && ordered[j].cells.contains(where: { cellSet.contains($0) })
            }
        }

        iterations = 0
        usedWords = []
        guard backtrack(index: 0, slots: ordered, intersections: intersections, grid: &grid, rng: &rng) else { return nil }
        return grid
    }

    nonisolated private mutating func backtrack(
        index: Int,
        slots: [WordSlot],
        intersections: [[Int]],
        grid: inout [[Character]],
        rng: inout some RandomNumberGenerator
    ) -> Bool {
        iterations += 1
        if iterations > maxIterations { return false }
        if index == slots.count { return true }

        let slot = slots[index]

        // Build pattern from letters already placed by prior slots.
        var pattern = Array(repeating: Optional<Character>.none, count: slot.length)
        for (i, coord) in slot.cells.enumerated() {
            let ch = grid[coord.row][coord.col]
            if ch != " " { pattern[i] = ch }
        }

        let candidates = validator.sampleWords(ofLength: slot.length, matching: pattern, maxCount: maxCandidatesPerSlot, using: &rng)
            .filter { !usedWords.contains($0) }

        for word in candidates {
            let chars = Array(word)

            for (i, coord) in slot.cells.enumerated() {
                if pattern[i] == nil { grid[coord.row][coord.col] = chars[i] }
            }

            usedWords.insert(word)

            if forwardCheck(index: index, slots: slots, intersections: intersections[index], grid: grid) {
                if backtrack(index: index + 1, slots: slots, intersections: intersections, grid: &grid, rng: &rng) {
                    return true
                }
            }

            usedWords.remove(word)

            for (i, coord) in slot.cells.enumerated() {
                if pattern[i] == nil { grid[coord.row][coord.col] = " " }
            }
        }

        return false
    }

    /// Checks that every slot intersecting the just-placed slot still has
    /// at least one valid, non-duplicate candidate.
    nonisolated private func forwardCheck(
        index: Int,
        slots: [WordSlot],
        intersections: [Int],
        grid: [[Character]]
    ) -> Bool {
        for j in intersections {
            let other = slots[j]
            var pattern = Array(repeating: Optional<Character>.none, count: other.length)
            for (i, coord) in other.cells.enumerated() {
                let ch = grid[coord.row][coord.col]
                if ch != " " { pattern[i] = ch }
            }
            if !validator.hasWords(ofLength: other.length, matching: pattern, excluding: usedWords) {
                return false
            }
        }
        return true
    }
}
