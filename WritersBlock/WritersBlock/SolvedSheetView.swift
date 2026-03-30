import SwiftUI

struct SolvedSheetView: View {
    let difficulty: Difficulty
    let seconds: Int
    let isPractice: Bool
    let isPersonalBest: Bool
    let onDone: () -> Void
    let onNextPuzzle: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.eqGreen.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.eqGreen)
                }

                VStack(spacing: 6) {
                    Text("Puzzle Solved!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.eqText)

                    Text("Completed in \(seconds.formattedAsTime())")
                        .font(.system(size: 16))
                        .foregroundColor(.eqTextDim)

                    if isPersonalBest {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("New personal best!")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.eqAmber)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.eqAmber.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 10) {
                if let nextPuzzle = onNextPuzzle {
                    Button(action: nextPuzzle) {
                        Text("Next Puzzle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.eqBrandPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                }

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.eqTextDim)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.eqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.eqBorder, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
        }
    }
}
