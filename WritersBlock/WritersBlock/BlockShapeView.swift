import SwiftUI

struct BlockShapeView: View {
    let block: LetterBlock
    let cellSize: CGFloat
    let isOverlay: Bool
    var isHint: Bool = false
    var gap: CGFloat = 0

    var body: some View {
        let palette = block.palette
        let totalW = CGFloat(block.cols) * cellSize + CGFloat(block.cols - 1) * gap
        let totalH = CGFloat(block.rows) * cellSize + CGFloat(block.rows - 1) * gap

        ZStack(alignment: .topLeading) {
            ForEach(block.cells.indices, id: \.self) { i in
                let cell   = block.cells[i]
                let letter = block.letters[cell]!
                let x = CGFloat(cell.col) * (cellSize + gap)
                let y = CGFloat(cell.row) * (cellSize + gap)

                ZStack {
                    RoundedRectangle(cornerRadius: isOverlay ? 6 : 5)
                        .fill(palette.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: isOverlay ? 6 : 5)
                                .strokeBorder(
                                    isHint ? Color.eqAmber : palette.border,
                                    lineWidth: isHint ? 2.5 : 1.5
                                )
                        )

                    Text(String(letter).uppercased())
                        .font(.system(size: cellSize * 0.45, weight: .bold, design: .rounded))
                        .foregroundColor(palette.text)
                        .minimumScaleFactor(0.5)
                }
                .frame(width: cellSize, height: cellSize)
                .offset(x: x, y: y)
            }
        }
        .frame(width: totalW, height: totalH)
    }
}
