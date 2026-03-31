import SwiftUI
import UIKit

// MARK: - PuzzleGridView

struct PuzzleGridView: View {
    @Binding var vm: PuzzleState
    let availableWidth: CGFloat

    var body: some View {
        let gs = vm.puzzle.gridSize
        let m = GridMetrics.compute(availableWidth: availableWidth, gridSize: gs)

        VStack(spacing: m.gap) {
            ForEach(0..<gs, id: \.self) { r in
                HStack(spacing: m.gap) {
                    ForEach(0..<gs, id: \.self) { c in
                        interiorCell(coord: GridCoordinate(row: r, col: c), m: m)
                    }
                }
            }
        }
        .frame(width: availableWidth, height: availableWidth)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { vm.gridOrigin = geo.frame(in: .global).origin }
                    .onChange(of: geo.frame(in: .global)) { _, frame in
                        vm.gridOrigin = frame.origin
                    }
                    .onChange(of: vm.dragState?.currentLocation) { _, location in
                        guard let location else { vm.ghostResult = nil; return }
                        vm.updateGhost(at: location, gridOrigin: geo.frame(in: .global).origin)
                    }
            }
        )
        .onAppear {
            vm.cellSize = m.cellSize
            vm.gap      = m.gap
        }
        .onChange(of: availableWidth) { _, _ in
            vm.cellSize = m.cellSize
            vm.gap      = m.gap
        }
    }

    @ViewBuilder
    private func interiorCell(coord: GridCoordinate, m: GridMetrics) -> some View {
        let isBlack  = vm.puzzle.blackSquares.contains(coord)
        let placed   = vm.placedLetters[coord]
        let ghostCells  = vm.ghostResult?.targetCells ?? []
        let isGhost     = ghostCells.contains(coord)
        let isValidGhost = vm.ghostResult?.isValid ?? false
        let hintedCells: Set<GridCoordinate> = {
            guard let hid = vm.hintedSlotId,
                  let slot = vm.slots.first(where: { $0.id == hid }) else { return [] }
            return Set(slot.cells)
        }()
        let isHinted = hintedCells.contains(coord)
        let cellNumber = vm.puzzle.cellNumbers[coord]

        if isBlack {
            BlackCellView(size: m.cellSize)
        } else {
            LetterCellView(
                coord: coord,
                placed: placed,
                isGhost: isGhost,
                isValidGhost: isValidGhost,
                isHinted: isHinted,
                cellNumber: cellNumber,
                size: m.cellSize
            )
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        let moved = hypot(value.translation.width, value.translation.height) > 8
                        guard moved else { return }
                        if vm.dragState != nil {
                            vm.updateDrag(to: value.location)
                        } else {
                            guard let cell = vm.placedLetters[coord],
                                  !cell.isAnchor, let blockId = cell.blockId else { return }
                            let blockCells = vm.placedLetters.filter { $0.value.blockId == blockId }.map(\.key)
                            let minRow = blockCells.map(\.row).min() ?? coord.row
                            let minCol = blockCells.map(\.col).min() ?? coord.col
                            let grabCell = GridCoordinate(row: coord.row - minRow, col: coord.col - minCol)
                            vm.removePlaced(at: coord)
                            vm.beginDrag(blockId: blockId, at: value.location, grabCell: grabCell)
                        }
                    }
                    .onEnded { value in
                        let moved = hypot(value.translation.width, value.translation.height) > 8
                        if vm.dragState != nil {
                            vm.commitDrop()
                        } else if !moved, let cell = placed, !cell.isAnchor {
                            vm.removePlaced(at: coord)
                        }
                    }
            )
        }
    }
}

// MARK: - BlackCellView

struct BlackCellView: View {
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.eqText.opacity(0.85))
            .frame(width: size, height: size)
    }
}

// MARK: - LetterCellView

struct LetterCellView: View {
    let coord: GridCoordinate
    let placed: PlacedLetter?
    let isGhost: Bool
    let isValidGhost: Bool
    let isHinted: Bool
    let cellNumber: Int?
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            cellBackground
            if let num = cellNumber {
                Text("\(num)")
                    .font(.system(size: max(7, size * 0.18), weight: .semibold))
                    .foregroundColor(placed != nil ? numberColor(for: placed!) : .eqMuted)
                    .padding(max(2, size * 0.07))
                    .allowsHitTesting(false)
            }
            if let p = placed {
                Text(String(p.letter).uppercased())
                    .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                    .foregroundColor(letterColor(for: p))
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(a11yLabel)
    }

    @ViewBuilder
    private var cellBackground: some View {
        if let p = placed {
            if p.isAnchor {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.eqAnchorBg)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.eqAnchorGold, lineWidth: 1.5))
            } else if let blockId = p.blockId {
                let palette = BlockPalette.forBlock(id: blockId)
                RoundedRectangle(cornerRadius: 6)
                    .fill(palette.background)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(palette.border, lineWidth: 1.5))
            }
        } else if isGhost {
            RoundedRectangle(cornerRadius: 6)
                .fill(isValidGhost ? Color.eqGreen.opacity(0.4) : Color.eqRed.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isValidGhost ? Color.eqGreen : Color.eqRed, lineWidth: 1.5)
                )
        } else if isHinted {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.eqAmber.opacity(0.25))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.eqAmber, lineWidth: 1.5))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.eqSurfaceHigh)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.eqBorder, lineWidth: 1))
        }
    }

    private func numberColor(for p: PlacedLetter) -> Color {
        if p.isAnchor { return .eqAnchorText.opacity(0.7) }
        guard let blockId = p.blockId else { return .eqMuted }
        return BlockPalette.forBlock(id: blockId).text.opacity(0.7)
    }

    private func letterColor(for p: PlacedLetter) -> Color {
        if p.isAnchor { return .eqAnchorText }
        guard let blockId = p.blockId else { return .eqText }
        return BlockPalette.forBlock(id: blockId).text
    }

    private var a11yLabel: String {
        let r = coord.row + 1, c = coord.col + 1
        if let p = placed {
            return p.isAnchor
                ? "Row \(r), column \(c): \(p.letter), anchor, fixed"
                : "Row \(r), column \(c): \(p.letter)"
        }
        if isGhost { return "Row \(r), column \(c), drop target" }
        return "Row \(r), column \(c), empty"
    }
}
