import SwiftUI

// MARK: - Grid coordinate

struct GridCoordinate: Sendable {
    let row: Int
    let col: Int
}

nonisolated extension GridCoordinate: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(col)
    }

    static func == (lhs: GridCoordinate, rhs: GridCoordinate) -> Bool {
        lhs.row == rhs.row && lhs.col == rhs.col
    }
}

// MARK: - Drag state

struct DragState {
    let blockId: Int
    var currentLocation: CGPoint
    var grabCell: GridCoordinate = GridCoordinate(row: 0, col: 0)
}

// MARK: - Ghost result

struct GhostResult {
    let anchorCell: GridCoordinate
    let targetCells: [GridCoordinate]
    let isValid: Bool
}

// MARK: - Grid metrics

struct GridMetrics {
    let cellSize: CGFloat
    let gap: CGFloat

    static func compute(availableWidth: CGFloat, gridSize: Int = 5) -> GridMetrics {
        let gap: CGFloat = 0
        let cellSize = max(22, availableWidth / CGFloat(gridSize))
        return GridMetrics(cellSize: cellSize, gap: gap)
    }
}

// MARK: - Time formatting

extension Int {
    func formattedAsTime() -> String {
        "\(self / 60):\(String(format: "%02d", self % 60))"
    }
}
