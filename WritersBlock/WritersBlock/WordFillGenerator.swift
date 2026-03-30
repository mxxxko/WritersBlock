import Foundation

struct WordFillGenerator {
    let validator: WordValidator
    private var iterations = 0
    private let maxIterations = 3_000
    private let maxCandidatesPerSlot = 40

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

        // Longest-first = most-constrained-first:
        // Longer slots have fewer valid words and more intersections.
        // Placing them first fails fast on bad black-square layouts instead
        // of discovering dead ends after filling most of the grid.
        let ordered = slots.sorted { $0.length > $1.length }

        iterations = 0
        guard backtrack(index: 0, slots: ordered, grid: &grid, rng: &rng) else { return nil }
        return grid
    }

    nonisolated private mutating func backtrack(
        index: Int,
        slots: [WordSlot],
        grid: inout [[Character]],
        rng: inout some RandomNumberGenerator
    ) -> Bool {
        iterations += 1
        if iterations > maxIterations { return false }
        if index == slots.count { return true }

        let slot = slots[index]

        // Build pattern from letters already written by previously placed slots
        var pattern = Array(repeating: Optional<Character>.none, count: slot.length)
        for (i, coord) in slot.cells.enumerated() {
            let ch = grid[coord.row][coord.col]
            if ch != " " { pattern[i] = ch }
        }

        let candidates = validator.sampleWords(ofLength: slot.length, matching: pattern, maxCount: maxCandidatesPerSlot, using: &rng)

        for word in candidates {
            let chars = Array(word)

            // Place only the cells that were empty
            for (i, coord) in slot.cells.enumerated() {
                if pattern[i] == nil { grid[coord.row][coord.col] = chars[i] }
            }

            // Forward check: for every remaining slot that shares a cell with this one,
            // verify it still has at least one valid candidate. Detects dead ends
            // immediately rather than after recursing many more levels.
            if forwardCheck(after: slot, remaining: slots[(index + 1)...], grid: grid) {
                if backtrack(index: index + 1, slots: slots, grid: &grid, rng: &rng) {
                    return true
                }
            }

            // Undo only the cells this slot wrote
            for (i, coord) in slot.cells.enumerated() {
                if pattern[i] == nil { grid[coord.row][coord.col] = " " }
            }
        }

        return false
    }

    /// Returns false if any remaining slot that intersects `placed` now has zero valid candidates.
    nonisolated private func forwardCheck(
        after placed: WordSlot,
        remaining: ArraySlice<WordSlot>,
        grid: [[Character]]
    ) -> Bool {
        let placedCells = Set(placed.cells)
        for other in remaining {
            // Only bother checking slots that actually share a cell with the placed slot
            guard other.cells.contains(where: { placedCells.contains($0) }) else { continue }

            var otherPattern = Array(repeating: Optional<Character>.none, count: other.length)
            for (i, coord) in other.cells.enumerated() {
                let ch = grid[coord.row][coord.col]
                if ch != " " { otherPattern[i] = ch }
            }

            if !validator.hasWords(ofLength: other.length, matching: otherPattern) {
                return false
            }
        }
        return true
    }
}
