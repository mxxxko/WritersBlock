import SwiftUI
import UIKit

struct PuzzleState {

    // MARK: - State

    let puzzle: WordPuzzleData
    let difficulty: Difficulty
    let isPractice: Bool
    let seed: Int?

    var placedLetters: [GridCoordinate: PlacedLetter] = [:]
    var blocks: [LetterBlock]
    var slots: [WordSlot]
    var dragState: DragState? = nil
    var ghostResult: GhostResult? = nil
    var elapsedSeconds: Int = 0
    var isSolved: Bool = false
    var showSolvedSheet: Bool = false
    var timerRunning: Bool = false
    var showSolutionConfirm: Bool = false
    var solutionWasShown: Bool = false
    var prePlaced: Set<Int> = []

    // Grid metrics — set by PuzzleGridView on appear
    var cellSize: CGFloat = 54
    var gap: CGFloat = 0
    var gridOrigin: CGPoint = .zero

    // MARK: - Init

    init(
        difficulty: Difficulty,
        isPractice: Bool = false,
        startSolved: Bool = false,
        solvedSeconds: Int = 0,
        practiceSeed: Int? = nil,
        puzzleData: WordPuzzleData? = nil,
        prePlace: Set<Int> = []
    ) {
        self.difficulty = difficulty
        self.isPractice = isPractice
        self.seed = practiceSeed

        let data: WordPuzzleData
        if let given = puzzleData {
            data = given
        } else if isPractice, let s = practiceSeed {
            data = WordPuzzleGenerator.make(for: difficulty, seed: s)
        } else {
            data = WordPuzzleGenerator.makeDaily(for: difficulty)
        }

        self.puzzle = data
        self.blocks = data.blocks
        self.slots  = data.slots

        // Place anchors
        for coord in data.anchors {
            let letter = data.solution[coord.row][coord.col]
            placedLetters[coord] = PlacedLetter(letter: letter, blockId: nil, isAnchor: true)
        }

        if !startSolved {
            // Randomly rotate each block so the user must find the right orientation
            for i in blocks.indices {
                let rotations = Int.random(in: 0...3)
                for _ in 0..<rotations { blocks[i].rotateClockwise() }
            }

            // Pre-place specified blocks (tutorial/howToPlay usage)
            if !prePlace.isEmpty {
                for blockId in prePlace {
                    guard blockId < blocks.count,
                          let anchor = data.blockSolutions[blockId] else { continue }
                    blocks[blockId] = data.blocks[blockId]  // restore solution orientation
                    for cell in blocks[blockId].cells {
                        let target = GridCoordinate(row: anchor.row + cell.row, col: anchor.col + cell.col)
                        if let letter = blocks[blockId].letters[cell] {
                            placedLetters[target] = PlacedLetter(letter: letter, blockId: blockId, isAnchor: false)
                        }
                    }
                    blocks[blockId].isPlaced = true
                }
                prePlaced = prePlace
                revalidateAllSlots()
            }

            timerRunning = true
        } else {
            placeSolution()
            elapsedSeconds = solvedSeconds
            isSolved = true
        }
    }

    // MARK: - Drag API

    mutating func beginDrag(blockId: Int, at location: CGPoint, grabCell: GridCoordinate = GridCoordinate(row: 0, col: 0)) {
        guard blockId < blocks.count, !blocks[blockId].isPlaced else { return }
        dragState = DragState(blockId: blockId, currentLocation: location, grabCell: grabCell)
        timerRunning = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    mutating func updateDrag(to location: CGPoint) {
        dragState?.currentLocation = location
    }

    mutating func commitDrop() {
        defer { dragState = nil; ghostResult = nil }
        guard let drag = dragState,
              let ghost = ghostResult, ghost.isValid else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        let block = blocks[drag.blockId]
        let offset = ghost.anchorCell
        var affected = Set<GridCoordinate>()
        for cell in block.cells {
            let target = GridCoordinate(row: offset.row + cell.row, col: offset.col + cell.col)
            if let letter = block.letters[cell] {
                placedLetters[target] = PlacedLetter(letter: letter, blockId: drag.blockId, isAnchor: false)
                affected.insert(target)
            }
        }
        blocks[drag.blockId].isPlaced = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        revalidateSlots(for: affected)
        checkSolved()
    }

    mutating func cancelDrag() {
        dragState = nil
        ghostResult = nil
    }

    mutating func removePlaced(at coord: GridCoordinate) {
        guard let cell = placedLetters[coord],
              !cell.isAnchor,
              let blockId = cell.blockId,
              !prePlaced.contains(blockId) else { return }
        var affected = Set<GridCoordinate>()
        let toRemove = placedLetters.filter { $0.value.blockId == blockId }.map(\.key)
        for key in toRemove {
            placedLetters.removeValue(forKey: key)
            affected.insert(key)
        }
        blocks[blockId].isPlaced = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        revalidateSlots(for: affected)
    }

    mutating func rotateBlock(id: Int) {
        guard id < blocks.count, !blocks[id].isPlaced else { return }
        blocks[id].rotateClockwise()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    /// Rotates a random unplaced block to its correct solution orientation.
    /// The user still has to find where to place it.
    @discardableResult
    mutating func applyHint() -> Int? {
        let unplaced = blocks.indices.filter { !blocks[$0].isPlaced && !prePlaced.contains($0) }
        guard let blockId = unplaced.randomElement() else { return nil }
        blocks[blockId] = puzzle.blocks[blockId]
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        return blockId
    }

    mutating func showSolution() {
        for i in blocks.indices { blocks[i] = puzzle.blocks[i]; blocks[i].isPlaced = false }
        placedLetters = [:]
        for coord in puzzle.anchors {
            let letter = puzzle.solution[coord.row][coord.col]
            placedLetters[coord] = PlacedLetter(letter: letter, blockId: nil, isAnchor: true)
        }
        placeSolution()
        isSolved = true
        solutionWasShown = true
        timerRunning = false
        dragState = nil
        ghostResult = nil
        revalidateAllSlots()
    }

    mutating func reset() {
        for i in blocks.indices where !prePlaced.contains(i) { blocks[i].isPlaced = false }
        placedLetters = [:]
        for coord in puzzle.anchors {
            let letter = puzzle.solution[coord.row][coord.col]
            placedLetters[coord] = PlacedLetter(letter: letter, blockId: nil, isAnchor: true)
        }
        // Restore pre-placed blocks
        for blockId in prePlaced {
            guard blockId < blocks.count, let anchor = puzzle.blockSolutions[blockId] else { continue }
            for cell in blocks[blockId].cells {
                let target = GridCoordinate(row: anchor.row + cell.row, col: anchor.col + cell.col)
                if let letter = blocks[blockId].letters[cell] {
                    placedLetters[target] = PlacedLetter(letter: letter, blockId: blockId, isAnchor: false)
                }
            }
        }
        isSolved = false
        showSolvedSheet = false
        showSolutionConfirm = false
        timerRunning = true
        revalidateAllSlots()
    }

    mutating func pauseTimer()  { timerRunning = false }
    mutating func resumeTimer() { guard !isSolved else { return }; timerRunning = true }

    var timerDisplay: String { elapsedSeconds.formattedAsTime() }

    var shareCode: String? {
        guard isPractice, let s = seed else { return nil }
        let prefix: String
        switch difficulty {
        case .easy:        prefix = "E"
        case .normal:      prefix = "N"
        case .hard:        prefix = "H"
        case .challenging: prefix = "C"
        }
        return "\(prefix)\(s)"
    }

    // MARK: - Ghost computation

    mutating func updateGhost(at location: CGPoint, gridOrigin: CGPoint) {
        guard let drag = dragState else { ghostResult = nil; return }
        let block = blocks[drag.blockId]
        let gs = puzzle.gridSize

        let borderOffset: CGFloat = 0
        let cellStep = cellSize + gap

        let fx = location.x - gridOrigin.x - borderOffset - cellSize / 2
        let fingerCol = Int(round(fx / cellStep))

        let fyBottom = (location.y - 0.5 * cellSize) - gridOrigin.y - borderOffset - cellSize / 2
        let bottomRow = Int(round(fyBottom / cellStep))

        let col = fingerCol
        let row = bottomRow - (block.rows - 1) + block.rows / 2

        guard bottomRow >= 0 && bottomRow < gs && col + block.cols > 0 && col < gs else {
            ghostResult = nil
            return
        }

        let targetCells = block.cells.map { GridCoordinate(row: row + $0.row, col: col + $0.col) }

        let inBounds  = targetCells.allSatisfy { $0.row >= 0 && $0.row < gs && $0.col >= 0 && $0.col < gs }
        let notBlack  = targetCells.allSatisfy { !puzzle.blackSquares.contains($0) }
        let notAnchor = targetCells.allSatisfy { !puzzle.anchors.contains($0) }
        let notPlaced = targetCells.allSatisfy { placedLetters[$0] == nil }

        let physicallyValid = inBounds && notBlack && notAnchor && notPlaced

        var isValid = physicallyValid
        if physicallyValid {
            // Build hypothetical letters map for slot check
            var dropped: [GridCoordinate: Character] = [:]
            for (tc, bc) in zip(targetCells, block.cells) {
                if let letter = block.letters[bc] { dropped[tc] = letter }
            }
            isValid = !wouldCompleteInvalidSlot(droppedLetters: dropped)
        }

        let wasValid = ghostResult?.isValid
        if wasValid != isValid { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }

        ghostResult = GhostResult(anchorCell: GridCoordinate(row: row, col: col), targetCells: targetCells, isValid: isValid)
    }

    // MARK: - Slot validation

    private func wouldCompleteInvalidSlot(droppedLetters: [GridCoordinate: Character]) -> Bool {
        for slot in puzzle.slots {
            let slotLetters: [Character?] = slot.cells.map { coord in
                droppedLetters[coord] ?? placedLetters[coord]?.letter
            }
            guard slotLetters.allSatisfy({ $0 != nil }) else { continue }
            let word = String(slotLetters.compactMap { $0 })
            if !WordValidator.shared.isValid(word) { return true }
        }
        return false
    }

    private mutating func revalidateSlots(for affectedCells: Set<GridCoordinate>) {
        for i in slots.indices {
            guard slots[i].cells.contains(where: { affectedCells.contains($0) }) else { continue }
            let letters = slots[i].cells.map { placedLetters[$0]?.letter }
            if letters.allSatisfy({ $0 != nil }) {
                let word = String(letters.compactMap { $0 })
                slots[i].validationState = WordValidator.shared.isValid(word) ? .valid : .invalid
            } else {
                slots[i].validationState = .empty
            }
        }
    }

    private mutating func revalidateAllSlots() {
        let allCells = Set(puzzle.slots.flatMap(\.cells))
        revalidateSlots(for: allCells)
    }

    // MARK: - Win check

    private mutating func checkSolved() {
        guard blocks.allSatisfy(\.isPlaced) else { return }
        guard slots.allSatisfy({ $0.validationState == .valid }) else { return }
        isSolved = true
        showSolvedSheet = true
        timerRunning = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Private helpers

    private mutating func placeSolution() {
        for (blockId, anchor) in puzzle.blockSolutions {
            guard blockId < blocks.count else { continue }
            let block = puzzle.blocks[blockId]
            for cell in block.cells {
                let target = GridCoordinate(row: anchor.row + cell.row, col: anchor.col + cell.col)
                if let letter = block.letters[cell] {
                    placedLetters[target] = PlacedLetter(letter: letter, blockId: blockId, isAnchor: false)
                }
            }
            blocks[blockId].isPlaced = true
        }
    }
}
