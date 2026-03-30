import SwiftUI

struct SplashView: View {
    @Binding var isShowing: Bool

    @State private var appeared      = false
    @State private var lettersDropped = false
    @State private var zooming       = false

    private struct Cell: Identifiable {
        let id: Int
        let colorIndex: Int
        let rippleDelay: Double
        let letter: String?
        let dropDelay:  Double
    }

    // Diagonal (row == col) → B L O C K S
    private static let letterMap: [Int: String] = [
        0: "B", 7: "L", 14: "O",
        21: "C", 28: "K", 35: "S",
    ]

    private static let colorMap = [
        0, 0, 1, 1, 2, 2,
        0, 3, 3, 1, 2, 4,
        5, 3, 6, 6, 4, 4,
        5, 5, 6, 7, 7, 4,
        5, 1, 1, 7, 2, 3,
        0, 0, 3, 7, 6, 6,
    ]

    private static let cells: [Cell] = (0..<36).map { i in
        let row = i / 6, col = i % 6
        let dist = abs(row - 2) + abs(col - 2)
        return Cell(
            id: i,
            colorIndex: colorMap[i],
            rippleDelay: Double(dist) * 0.06,
            letter: letterMap[i],
            dropDelay: Double(row) * 0.09
        )
    }

    private let columns = Array(repeating: GridItem(.fixed(42), spacing: 5), count: 6)

    var body: some View {
        ZStack {
            Color.eqBackground.ignoresSafeArea()

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(Self.cells) { cell in
                    if cell.letter != nil {
                        letterCell(cell)
                    } else {
                        regularCell(cell)
                    }
                }
            }
            .frame(width: 42 * 6 + 5 * 5)
        }
        .opacity(zooming ? 0.0 : 1.0)
        .scaleEffect(zooming ? 2.2 : 1.0)
        .animation(.easeIn(duration: 0.32), value: zooming)
        .ignoresSafeArea()
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                lettersDropped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                zooming = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.82) {
                isShowing = false
            }
        }
    }

    // MARK: - Cell views

    private func regularCell(_ cell: Cell) -> some View {
        let palette = BlockPalette.forBlock(id: cell.colorIndex)
        return RoundedRectangle(cornerRadius: 8)
            .fill(palette.background)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.border, lineWidth: 1.5))
            .frame(width: 42, height: 42)
            .scaleEffect(appeared ? 1.0 : 0.01)
            .opacity(appeared ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.38, dampingFraction: 0.62).delay(cell.rippleDelay),
                value: appeared
            )
    }

    private func letterCell(_ cell: Cell) -> some View {
        let palette = BlockPalette.forBlock(id: cell.colorIndex)
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(palette.background)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.border, lineWidth: 1.5))
            Text(cell.letter ?? "")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(palette.text)
        }
        .frame(width: 42, height: 42)
        .opacity(lettersDropped ? 1.0 : 0.0)
        .offset(y: lettersDropped ? 0 : -320)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.62).delay(cell.dropDelay),
            value: lettersDropped
        )
    }
}
