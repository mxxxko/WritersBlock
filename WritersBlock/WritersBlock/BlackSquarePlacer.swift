import Foundation

struct BlackSquarePlacer {
    /// Places `count` black squares in an `gridSize`×`gridSize` grid.
    /// Ensures no horizontal or vertical run of white cells has length 1 or 2.
    nonisolated static func place(
        count: Int,
        gridSize: Int,
        using rng: inout some RandomNumberGenerator
    ) -> Set<GridCoordinate> {
        var blacks = Set<GridCoordinate>()

        // Build all candidate positions and shuffle
        let candidates = (0..<gridSize).flatMap { r in
            (0..<gridSize).map { c in GridCoordinate(row: r, col: c) }
        }.shuffled(using: &rng)

        for coord in candidates {
            guard blacks.count < count else { break }
            if isValidPlacement(coord, blacks: blacks, gridSize: gridSize) {
                blacks.insert(coord)
            }
        }

        // If we couldn't place enough, relax and accept what we have
        return blacks
    }

    nonisolated private static func isValidPlacement(
        _ coord: GridCoordinate,
        blacks: Set<GridCoordinate>,
        gridSize: Int
    ) -> Bool {
        var test = blacks
        test.insert(coord)
        // Check all rows and columns for short runs
        for r in 0..<gridSize where !checkLine(row: r, col: nil, blacks: test, gridSize: gridSize) { return false }
        for c in 0..<gridSize where !checkLine(row: nil, col: c, blacks: test, gridSize: gridSize) { return false }
        return true
    }

    /// Returns true if the row or column has no white runs of length 1 or 2.
    nonisolated private static func checkLine(
        row: Int?,
        col: Int?,
        blacks: Set<GridCoordinate>,
        gridSize: Int
    ) -> Bool {
        var runLen = 0
        for i in 0..<gridSize {
            let coord = row != nil
                ? GridCoordinate(row: row!, col: i)
                : GridCoordinate(row: i, col: col!)
            if blacks.contains(coord) {
                if runLen == 1 || runLen == 2 { return false }
                runLen = 0
            } else {
                runLen += 1
            }
        }
        return runLen != 1 && runLen != 2
    }
}
