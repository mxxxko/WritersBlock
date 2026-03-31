import Foundation

// MARK: - Seeded RNG

struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    nonisolated init(seed: Int) {
        var s = UInt64(bitPattern: Int64(seed)) &* 0x9e3779b97f4a7c15
        s = (s ^ (s >> 30)) &* 0xbf58476d1ce4e5b9
        s = (s ^ (s >> 27)) &* 0x94d049bb133111eb
        state = s ^ (s >> 31)
        if state == 0 { state = 1 }
    }

    nonisolated mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Generator

struct WordPuzzleGenerator {
    nonisolated private static let maxRetries = 50

    // MARK: - Public entry points

    nonisolated static func make(for difficulty: Difficulty, seed: Int? = nil) -> WordPuzzleData {
        let targetSeed = seed ?? Int.random(in: 100_000...999_999)
        for attempt in 0..<maxRetries {
            var rng = SeededRandom(seed: targetSeed + attempt)
            if let data = tryGenerate(difficulty: difficulty, seed: targetSeed + attempt, rng: &rng) {
                return data
            }
        }
        return fallback(for: difficulty, seed: targetSeed)
    }

    nonisolated(unsafe) private static var dailyCache: [String: WordPuzzleData] = [:]

    nonisolated static func makeDaily(for difficulty: Difficulty, date: Date = Date()) -> WordPuzzleData {
        let dateStr = DateFormatter.isoDate.string(from: date)
        let cacheKey = "\(dateStr)-\(difficulty.rawValue)"
        if let cached = dailyCache[cacheKey] { return cached }

        let raw = "WB-\(dateStr)-\(difficulty.rawValue)"
        var hash: UInt64 = 14695981039346656037
        for byte in raw.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        let seed = Int(hash % 900_000) + 100_000
        let data = make(for: difficulty, seed: seed)
        dailyCache[cacheKey] = data
        return data
    }

    // MARK: - Generation pipeline

    nonisolated private static func tryGenerate(
        difficulty: Difficulty,
        seed: Int,
        rng: inout SeededRandom
    ) -> WordPuzzleData? {
        let gridSize = difficulty.gridSize

        // Phase 1: black squares
        let blacks = BlackSquarePlacer.place(count: difficulty.blackCount, gridSize: gridSize, using: &rng)

        // Phase 2: extract slots (≥3 cells only)
        let slots = extractSlots(gridSize: gridSize, blacks: blacks)
        guard !slots.isEmpty else { return nil }

        // Phase 3: fill words
        var filler = WordFillGenerator(validator: WordValidator.shared)
        guard let solution = filler.fill(gridSize: gridSize, blacks: blacks, slots: slots, using: &rng) else {
            return nil
        }

        // Phase 4: piece partitioning (no anchors — all cells go into draggable blocks)
        let (blocks, blockSolutions) = partitionPieces(
            gridSize: gridSize, blacks: blacks, solution: solution, using: &rng
        )

        let finalSlots = slots.enumerated().map { i, s in
            WordSlot(id: i, direction: s.direction, cells: s.cells)
        }

        let (clues, slotLabels, cellNumbers) = buildCluesAndLabels(
            slots: finalSlots, solution: solution, rng: &rng
        )

        return WordPuzzleData(
            gridSize: gridSize,
            solution: solution,
            blackSquares: blacks,
            anchors: Set(),
            slots: finalSlots,
            blocks: blocks,
            blockSolutions: blockSolutions,
            seed: seed,
            difficulty: difficulty,
            clues: clues,
            slotLabels: slotLabels,
            cellNumbers: cellNumbers
        )
    }

    // MARK: - Slot extraction

    nonisolated static func extractSlots(gridSize: Int, blacks: Set<GridCoordinate>) -> [WordSlot] {
        var slots: [WordSlot] = []
        var nextId = 0

        func addSlot(_ direction: WordSlot.SlotDirection, _ cells: [GridCoordinate]) {
            guard cells.count >= 3 else { return }
            slots.append(WordSlot(id: nextId, direction: direction, cells: cells))
            nextId += 1
        }

        // Across
        for r in 0..<gridSize {
            var run: [GridCoordinate] = []
            for c in 0..<gridSize {
                let coord = GridCoordinate(row: r, col: c)
                if blacks.contains(coord) { addSlot(.across, run); run = [] }
                else { run.append(coord) }
            }
            addSlot(.across, run)
        }

        // Down
        for c in 0..<gridSize {
            var run: [GridCoordinate] = []
            for r in 0..<gridSize {
                let coord = GridCoordinate(row: r, col: c)
                if blacks.contains(coord) { addSlot(.down, run); run = [] }
                else { run.append(coord) }
            }
            addSlot(.down, run)
        }

        return slots
    }

    // MARK: - Piece partitioning

    nonisolated private static func partitionPieces(
        gridSize: Int,
        blacks: Set<GridCoordinate>,
        solution: [[Character]],
        using rng: inout some RandomNumberGenerator
    ) -> (blocks: [LetterBlock], solutions: [Int: GridCoordinate]) {
        var unassigned = Set<GridCoordinate>()
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let coord = GridCoordinate(row: r, col: c)
                if !blacks.contains(coord) {
                    unassigned.insert(coord)
                }
            }
        }

        var blocks: [LetterBlock] = []
        var blockSolutions: [Int: GridCoordinate] = [:]
        var orphans = Set<GridCoordinate>()
        var nextId = 0

        while !unassigned.isEmpty {
            guard let seed = unassigned.randomElement(using: &rng) else { break }
            unassigned.remove(seed)

            var pieceCells = [seed]

            for _ in 1..<4 {
                let candidates = adjacent(to: pieceCells, in: unassigned, gridSize: gridSize)
                guard !candidates.isEmpty else { break }

                // MRV: prefer cells with fewer remaining unassigned neighbours —
                // grabbing "at-risk" cells first prevents them from becoming orphans.
                let scored = candidates.map { c -> (GridCoordinate, Int) in
                    let free = adjacent(to: [c], in: unassigned, gridSize: gridSize)
                        .filter { !pieceCells.contains($0) }.count
                    return (c, free)
                }
                let minFree = scored.min(by: { $0.1 < $1.1 })!.1
                let best = scored.filter { $0.1 == minFree }.map { $0.0 }
                let next = best.randomElement(using: &rng)!
                pieceCells.append(next)
                unassigned.remove(next)
            }

            // Reject I-tetromino (4-cell straight line) — trim to 3 cells
            if pieceCells.count == 4 && isITetromino(pieceCells) {
                let extra = pieceCells.removeLast()
                unassigned.insert(extra)
            }

            // If isolated (all neighbours already claimed), queue for pairing pass
            if pieceCells.count == 1 {
                orphans.insert(seed)
                continue
            }

            let minRow = pieceCells.map(\.row).min()!
            let minCol = pieceCells.map(\.col).min()!

            let relative = pieceCells.map { GridCoordinate(row: $0.row - minRow, col: $0.col - minCol) }
            var letterMap: [GridCoordinate: Character] = [:]
            for (i, absCell) in pieceCells.enumerated() {
                letterMap[relative[i]] = solution[absCell.row][absCell.col]
            }

            blocks.append(LetterBlock(id: nextId, cells: relative, letters: letterMap))
            blockSolutions[nextId] = GridCoordinate(row: minRow, col: minCol)
            nextId += 1
        }

        // Build reverse map: absolute coord → block array index
        var coordToBlock: [GridCoordinate: Int] = [:]
        for (bi, block) in blocks.enumerated() {
            let origin = blockSolutions[block.id]!
            for rel in block.cells {
                coordToBlock[GridCoordinate(row: origin.row + rel.row, col: origin.col + rel.col)] = bi
            }
        }

        let dirs = [(-1,0),(1,0),(0,-1),(0,1)]

        // Orphan pass 1: merge into any adjacent block that still has room (< 4 cells)
        var unmergedOrphans = Set<GridCoordinate>()
        for orphan in orphans {
            var merged = false
            for (dr, dc) in dirs {
                let n = GridCoordinate(row: orphan.row + dr, col: orphan.col + dc)
                if let bi = coordToBlock[n], blocks[bi].cells.count < 4 {
                    let origin = blockSolutions[blocks[bi].id]!
                    let rel = GridCoordinate(row: orphan.row - origin.row, col: orphan.col - origin.col)
                    blocks[bi].cells.append(rel)
                    blocks[bi].letters[rel] = solution[orphan.row][orphan.col]
                    coordToBlock[orphan] = bi
                    merged = true
                    break
                }
            }
            if !merged { unmergedOrphans.insert(orphan) }
        }

        // Orphan pass 2: pair adjacent orphans into 2-cell dominoes
        var processed = Set<GridCoordinate>()
        for orphan in unmergedOrphans {
            guard !processed.contains(orphan) else { continue }
            var partner: GridCoordinate? = nil
            for (dr, dc) in dirs {
                let n = GridCoordinate(row: orphan.row + dr, col: orphan.col + dc)
                if unmergedOrphans.contains(n), !processed.contains(n) { partner = n; break }
            }
            if let p = partner {
                let minRow = min(orphan.row, p.row), minCol = min(orphan.col, p.col)
                let rA = GridCoordinate(row: orphan.row - minRow, col: orphan.col - minCol)
                let rB = GridCoordinate(row: p.row - minRow, col: p.col - minCol)
                let newId = nextId; nextId += 1
                blocks.append(LetterBlock(id: newId, cells: [rA, rB],
                    letters: [rA: solution[orphan.row][orphan.col], rB: solution[p.row][p.col]]))
                blockSolutions[newId] = GridCoordinate(row: minRow, col: minCol)
                coordToBlock[orphan] = blocks.count - 1
                coordToBlock[p]      = blocks.count - 1
                processed.insert(orphan); processed.insert(p)
            } else {
                // Truly lone orphan: merge into the smallest adjacent block (last resort)
                var bestBi: Int? = nil
                var bestSize = Int.max
                for (dr, dc) in dirs {
                    let n = GridCoordinate(row: orphan.row + dr, col: orphan.col + dc)
                    if let bi = coordToBlock[n], blocks[bi].cells.count < bestSize {
                        bestBi = bi; bestSize = blocks[bi].cells.count
                    }
                }
                if let bi = bestBi {
                    let origin = blockSolutions[blocks[bi].id]!
                    let rel = GridCoordinate(row: orphan.row - origin.row, col: orphan.col - origin.col)
                    blocks[bi].cells.append(rel)
                    blocks[bi].letters[rel] = solution[orphan.row][orphan.col]
                    coordToBlock[orphan] = bi
                }
                processed.insert(orphan)
            }
        }

        return (blocks, blockSolutions)
    }

    nonisolated private static func adjacent(
        to cells: [GridCoordinate],
        in available: Set<GridCoordinate>,
        gridSize: Int
    ) -> [GridCoordinate] {
        let dirs = [(-1,0),(1,0),(0,-1),(0,1)]
        var result = Set<GridCoordinate>()
        for cell in cells {
            for (dr, dc) in dirs {
                let n = GridCoordinate(row: cell.row + dr, col: cell.col + dc)
                if n.row >= 0 && n.row < gridSize && n.col >= 0 && n.col < gridSize && available.contains(n) {
                    result.insert(n)
                }
            }
        }
        return Array(result)
    }

    nonisolated private static func isITetromino(_ cells: [GridCoordinate]) -> Bool {
        guard cells.count == 4 else { return false }
        return Set(cells.map(\.row)).count == 1 || Set(cells.map(\.col)).count == 1
    }

    // MARK: - Last-resort fallback

    nonisolated private static func fallback(for difficulty: Difficulty, seed: Int) -> WordPuzzleData {
        let gs = 5
        // Valid 5×5 word square — every row AND column spells a real word:
        // Across & Down: heart / ember / abuse / resin / trend
        let sol: [[Character]] = [
            ["h","e","a","r","t"],
            ["e","m","b","e","r"],
            ["a","b","u","s","e"],
            ["r","e","s","i","n"],
            ["t","r","e","n","d"]
        ]
        let blacks = Set<GridCoordinate>()
        let slots = extractSlots(gridSize: gs, blacks: blacks)
        var rng = SeededRandom(seed: seed)
        let (blks, blkSols) = partitionPieces(
            gridSize: gs, blacks: blacks, solution: sol, using: &rng
        )
        let finalSlots = slots.enumerated().map { i, s in WordSlot(id: i, direction: s.direction, cells: s.cells) }
        let (clues, slotLabels, cellNumbers) = buildCluesAndLabels(
            slots: finalSlots, solution: sol, rng: &rng
        )
        return WordPuzzleData(
            gridSize: gs, solution: sol, blackSquares: blacks,
            anchors: Set(), slots: finalSlots,
            blocks: blks, blockSolutions: blkSols, seed: seed, difficulty: .easy,
            clues: clues, slotLabels: slotLabels, cellNumbers: cellNumbers
        )
    }

    // MARK: - Clue & label assignment

    nonisolated private static func buildCluesAndLabels(
        slots: [WordSlot],
        solution: [[Character]],
        rng: inout some RandomNumberGenerator
    ) -> (clues: [Int: String], slotLabels: [Int: String], cellNumbers: [GridCoordinate: Int]) {
        // Assign crossword numbers to cells that start at least one slot,
        // ordered top-to-bottom, left-to-right.
        let startCells = Set(slots.map { $0.cells[0] })
        let sorted = startCells.sorted { $0.row != $1.row ? $0.row < $1.row : $0.col < $1.col }
        var cellNumbers: [GridCoordinate: Int] = [:]
        for (i, cell) in sorted.enumerated() { cellNumbers[cell] = i + 1 }

        var slotLabels: [Int: String] = [:]
        var clues: [Int: String] = [:]
        for slot in slots {
            let num = cellNumbers[slot.cells[0]] ?? 0
            let dir = slot.direction == .across ? "A" : "D"
            slotLabels[slot.id] = "\(num)\(dir)"
            let word = String(slot.cells.map { solution[$0.row][$0.col] })
            clues[slot.id] = WordValidator.shared.randomClue(for: word, using: &rng)
                ?? "\(slot.cells.count)-letter word"
        }
        return (clues, slotLabels, cellNumbers)
    }
}
