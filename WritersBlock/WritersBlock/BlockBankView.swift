import SwiftUI
import UIKit

// MARK: - BlockBankView

struct BlockBankView: View {
    @Binding var vm: PuzzleState

    private var bankCellSize: CGFloat { vm.blocks.count > 8 ? 16 : 22 }
    private var perRow: Int { vm.blocks.count > 8 ? 5 : 4 }
    private var slotSize: CGFloat { 4 * bankCellSize + 8 }

    var body: some View {
        let bcs = bankCellSize
        let ss  = slotSize
        let rows = stride(from: 0, to: vm.blocks.count, by: perRow).map { start in
            (start ..< min(start + perRow, vm.blocks.count)).map { $0 }
        }

        VStack(alignment: .center, spacing: 8) {
            ForEach(0 ..< rows.count, id: \.self) { r in
                HStack(alignment: .center, spacing: 8) {
                    ForEach(rows[r], id: \.self) { i in
                        BlockView(vm: $vm, blockIndex: i, cellSize: bcs, slotSize: ss)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .overlay(Rectangle().fill(Color.eqBorder).frame(height: 1), alignment: .top)
    }
}

// MARK: - BlockView

struct BlockView: View {
    @Binding var vm: PuzzleState
    let blockIndex: Int
    var cellSize: CGFloat = 22
    var slotSize: CGFloat = 96

    @State private var rotationScale: CGFloat = 1.0
    @State private var blockGlobalOrigin: CGPoint = .zero

    private var block: LetterBlock { vm.blocks[blockIndex] }
    private var isDragging: Bool { vm.dragState?.blockId == blockIndex }

    var body: some View {
        ZStack {
            BlockShapeView(block: block, cellSize: cellSize, isOverlay: false)
                .opacity(block.isPlaced ? 0.15 : isDragging ? 0.4 : 1.0)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: block.isPlaced)
                .scaleEffect(rotationScale)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { blockGlobalOrigin = geo.frame(in: .global).origin }
                            .onChange(of: geo.frame(in: .global)) { _, frame in
                                blockGlobalOrigin = frame.origin
                            }
                    }
                )
        }
        .frame(width: slotSize, height: slotSize)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    guard hypot(value.translation.width, value.translation.height) > 8 else { return }
                    if vm.dragState?.blockId != blockIndex {
                        let localStart = CGPoint(
                            x: value.startLocation.x - blockGlobalOrigin.x,
                            y: value.startLocation.y - blockGlobalOrigin.y
                        )
                        let grabCell = block.cells.min { a, b in
                            let ax = CGFloat(a.col) * cellSize + cellSize / 2 - localStart.x
                            let ay = CGFloat(a.row) * cellSize + cellSize / 2 - localStart.y
                            let bx = CGFloat(b.col) * cellSize + cellSize / 2 - localStart.x
                            let by = CGFloat(b.row) * cellSize + cellSize / 2 - localStart.y
                            return ax*ax + ay*ay < bx*bx + by*by
                        } ?? GridCoordinate(row: 0, col: 0)
                        vm.beginDrag(blockId: blockIndex, at: value.location, grabCell: grabCell)
                    } else {
                        vm.updateDrag(to: value.location)
                    }
                }
                .onEnded { value in
                    if hypot(value.translation.width, value.translation.height) > 8 {
                        vm.commitDrop()
                    } else {
                        if !block.isPlaced {
                            rotationScale = 0.9
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                vm.rotateBlock(id: blockIndex)
                                rotationScale = 1.0
                            }
                        }
                        vm.cancelDrag()
                    }
                }
        )
    }
}
