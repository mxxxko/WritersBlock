import SwiftUI

struct HowToPlayView: View {
    let onBack: () -> Void
    @State private var vm: PuzzleState? = nil
    @State private var zstackOrigin: CGPoint = .zero
    @State private var puzzleWidth: CGFloat = 0

    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
    }

    private var remaining: Int { vm?.blocks.filter { !$0.isPlaced }.count ?? 0 }

    // Safe binding — only used when vm != nil
    private var vmBind: Binding<PuzzleState> {
        Binding(get: { self.vm! }, set: { self.vm = $0 })
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.eqBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                    instructionCards
                    puzzleSection
                        .animation(.easeInOut(duration: 0.25), value: vm?.isSolved ?? false)
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
                .frame(maxWidth: 520)
            }
            .scrollDisabled(vm?.dragState != nil)

            dragOverlay
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        zstackOrigin = geo.frame(in: .global).origin
                        puzzleWidth  = min(geo.size.width, 520) - 80
                    }
                    .onChange(of: geo.frame(in: .global)) { _, frame in
                        zstackOrigin = frame.origin
                    }
                    .onChange(of: geo.size.width) { _, w in
                        puzzleWidth = w - 80
                    }
            }
        )
        .task {
            guard vm == nil else { return }
            let data = await Task.detached(priority: .userInitiated) {
                WordPuzzleGenerator.make(for: .easy, seed: 12345)
            }.value
            vm = PuzzleState(
                difficulty: .easy,
                isPractice: true,
                startSolved: false,
                solvedSeconds: 0,
                practiceSeed: 12345,
                puzzleData: data
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.eqText)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, -12)

            Text("How to Play")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.eqText)

            Spacer()
        }
    }

    // MARK: - Instruction Cards

    private var instructionCards: some View {
        VStack(spacing: 12) {
            infoCard(
                icon: "textformat.abc",
                title: "The Goal",
                body: "Fill every white cell so each **across** and **down** slot spells a valid English word. Every block must fit exactly once."
            )
            infoCard(
                icon: "lock.fill",
                title: "Anchor Cells",
                body: "Gold-bordered cells are **fixed anchors** — they can't be moved. Use them as starting points to figure out where each letter block belongs."
            )
            infoCard(
                icon: "hand.draw",
                title: "Placing Blocks",
                body: "Drag a block from the bank **onto the grid**. A **green** highlight means the placement is valid; **red** means it conflicts. Release to drop."
            )
            infoCard(
                icon: "arrow.clockwise",
                title: "Rotating & Removing",
                body: "**Tap** a block in the bank to rotate it clockwise. **Drag** or **tap** a placed block on the grid to pick it up and try a different spot."
            )
            infoCard(
                icon: "checkmark.seal",
                title: "Word Validation",
                body: "Border cells show **✓** or **✗** as you fill each slot. When every slot is valid and all blocks are placed, the puzzle is solved!"
            )
        }
    }

    private func infoCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.eqAmber)
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.eqText)
                Text(LocalizedStringKey(body))
                    .font(.system(size: 13))
                    .foregroundColor(.eqTextDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.eqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.eqBorder, lineWidth: 1)
        )
    }

    // MARK: - Puzzle Section

    @ViewBuilder
    private var puzzleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Try It Yourself")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.eqText)
                if vm?.isSolved == true {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.eqGreen)
                        Text("You solved it! Well done!")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.eqText)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Text("Drag the **\(remaining) \(remaining == 1 ? "block" : "blocks")** from the bank onto the grid to spell words in every row and column.")
                        .font(.system(size: 13))
                        .foregroundColor(.eqTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if vm != nil {
                PuzzleGridView(vm: vmBind, availableWidth: puzzleWidth)

                Group {
                    if vm!.dragState != nil {
                        Text("Drop to place · tap a placed letter to remove")
                            .foregroundColor(.eqMuted)
                    } else if remaining > 0 {
                        Text("\(remaining) block\(remaining == 1 ? "" : "s") remaining · tap to rotate")
                            .foregroundColor(.eqMuted)
                    } else {
                        Text("All blocks placed!")
                            .foregroundColor(.eqGreen)
                    }
                }
                .font(.system(size: 12))
                .frame(height: 18)

                BlockBankView(vm: vmBind)

                HStack {
                    Spacer()
                    Button(action: { vm?.reset() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.eqTextDim)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.eqSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.eqBorder, lineWidth: 1)
                            )
                    }
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.eqTextDim)
                    Spacer()
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: - Drag Overlay

    @ViewBuilder
    private var dragOverlay: some View {
        if let vm = vm, let drag = vm.dragState {
            let block = vm.blocks[drag.blockId]
            let cs = vm.cellSize
            let gap = vm.gap
            let h = CGFloat(block.rows) * cs + CGFloat(block.rows - 1) * gap
            let tly = drag.currentLocation.y - h
            let center = CGPoint(
                x: drag.currentLocation.x - zstackOrigin.x,
                y: tly - zstackOrigin.y + h / 2
            )
            BlockShapeView(block: block, cellSize: cs, isOverlay: true, gap: gap)
                .opacity(0.85)
                .position(x: center.x, y: center.y)
                .allowsHitTesting(false)
        }
    }
}
