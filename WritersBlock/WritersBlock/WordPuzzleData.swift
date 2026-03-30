import SwiftUI

// MARK: - Difficulty

enum Difficulty: String, CaseIterable, Hashable {
    case easy        = "Easy"
    case normal      = "Normal"
    case hard        = "Hard"
    case challenging = "Challenging"

    nonisolated var gridSize: Int {
        switch self {
        case .easy, .normal: return 5
        case .hard, .challenging: return 7
        }
    }

    nonisolated var blackCount: Int {
        switch self {
        case .easy: return 6
        case .normal: return 6
        case .hard: return 8
        case .challenging: return 10
        }
    }

    nonisolated var anchorFraction: Double {
        switch self {
        case .easy: return 0.30
        case .normal: return 0.25
        case .hard: return 0.22
        case .challenging: return 0.18
        }
    }

    var color: Color {
        switch self {
        case .easy:        return .eqGreen
        case .normal:      return .eqBrandPurple
        case .hard:        return .eqAmber
        case .challenging: return .eqRed
        }
    }

    var description: String {
        switch self {
        case .easy:        return "3–4 letter words · 5×5"
        case .normal:      return "3–5 letter words · 5×5"
        case .hard:        return "3–6 letter words · 7×7"
        case .challenging: return "3–7 letter words · 7×7"
        }
    }
}

// MARK: - Word slot

struct WordSlot: Identifiable {
    let id: Int
    let direction: SlotDirection
    let cells: [GridCoordinate]   // absolute grid positions in order
    var validationState: SlotValidation = .empty

    enum SlotDirection { case across, down }
    enum SlotValidation { case empty, valid, invalid }

    nonisolated var length: Int { cells.count }
}

// MARK: - Placed letter

struct PlacedLetter {
    let letter: Character
    let blockId: Int?    // nil = anchor
    let isAnchor: Bool
}

// MARK: - Letter block

struct LetterBlock: Identifiable {
    let id: Int
    var cells: [GridCoordinate]              // normalized relative coords
    var letters: [GridCoordinate: Character]
    var isPlaced: Bool = false

    var palette: BlockPalette { BlockPalette.forBlock(id: id) }
    var rows: Int { (cells.map(\.row).max() ?? 0) + 1 }
    var cols: Int { (cells.map(\.col).max() ?? 0) + 1 }

    mutating func rotateClockwise() {
        let maxRow = cells.map(\.row).max() ?? 0
        let rotated = cells.map { GridCoordinate(row: $0.col, col: maxRow - $0.row) }
        let minRow = rotated.map(\.row).min() ?? 0
        let minCol = rotated.map(\.col).min() ?? 0
        let normalized = rotated.map { GridCoordinate(row: $0.row - minRow, col: $0.col - minCol) }

        var newLetters: [GridCoordinate: Character] = [:]
        for (coord, letter) in letters {
            let nr = coord.col - minRow
            let nc = (maxRow - coord.row) - minCol
            newLetters[GridCoordinate(row: nr, col: nc)] = letter
        }
        cells = normalized
        letters = newLetters
    }
}

// MARK: - Puzzle data

struct WordPuzzleData {
    let gridSize: Int
    let solution: [[Character]]
    let blackSquares: Set<GridCoordinate>
    let anchors: Set<GridCoordinate>
    let slots: [WordSlot]
    let blocks: [LetterBlock]
    let blockSolutions: [Int: GridCoordinate]   // block id → top-left in solution
    let seed: Int
    let difficulty: Difficulty
}
