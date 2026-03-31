import SwiftUI

// MARK: - FlyingBlock

private struct FlyingBlock: Identifiable {
    let id: Int
    let block: LetterBlock
    let center: CGPoint
    let cellSize: CGFloat
    let gap: CGFloat
}

// MARK: - PuzzleView

struct PuzzleView: View {
    let difficulty: Difficulty
    let onBack: () -> Void
    let onNextPuzzle: (() -> Void)?
    let isPractice: Bool
    let practiceSeed: Int?

    @State private var vm: PuzzleState? = nil
    @State private var zstackOrigin: CGPoint = .zero
    @State private var puzzleAreaWidth: CGFloat = 0
    @State private var flyingBlocks: [FlyingBlock] = []
    @State private var flyingAnimating = false
    @State private var showHintConfirm = false
    @State private var tappedClueSlotId: Int? = nil
    @State private var tappedClueNum: Int? = nil
    let store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase

    init(difficulty: Difficulty, store: AppDataStore,
         isPractice: Bool = false, practiceSeed: Int? = nil,
         onBack: @escaping () -> Void, onNextPuzzle: (() -> Void)? = nil) {
        self.difficulty = difficulty
        self.store = store
        self.onBack = onBack
        self.onNextPuzzle = onNextPuzzle
        self.isPractice = isPractice
        self.practiceSeed = practiceSeed
    }

    // Safe force-unwrap binding — only used from within `if vm != nil` branches
    private var vmBind: Binding<PuzzleState> {
        Binding(get: { self.vm! }, set: { self.vm = $0 })
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.eqBackground.ignoresSafeArea()

            if vm != nil {
                VStack(spacing: 0) {
                    topBar.padding(.top, 8)

                    if vm!.isSolved {
                        solvedBanner
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer(minLength: 4)

                    PuzzleGridView(vm: vmBind, availableWidth: puzzleAreaWidth)
                        .padding(.horizontal, 60)

                    Spacer(minLength: 4)

                    CluesPanelView(
                        slots: vm!.slots,
                        clues: vm!.puzzle.clues,
                        hintedSlotId: vm!.hintedSlotId,
                        onTap: { slotId, num in
                            tappedClueSlotId = slotId
                            tappedClueNum = num
                        }
                    )
                    .padding(.horizontal, 16)

                    statusBar.padding(.top, 4).padding(.bottom, 4)

                    VStack(spacing: 0) {
                        BlockBankView(vm: vmBind)
                        resetButton
                            .padding(.top, 12)
                            .padding(.bottom, 28)
                    }
                    .background(Color.eqSurface.ignoresSafeArea(edges: .bottom))
                }
                .animation(.easeInOut(duration: 0.25), value: vm!.isSolved)

                dragOverlay
                flyingResetOverlay
                ConfettiView(isActive: vm!.showSolvedSheet)

                if vm!.showSolutionConfirm {
                    GameDialog(
                        title: "Show the solution?",
                        message: "This will reveal all the words.",
                        primaryLabel: "Yes, show it",
                        primaryIsDestructive: true,
                        primaryAction: { vm?.showSolutionConfirm = false; vm?.showSolution() },
                        dismissLabel: "Keep trying",
                        onDismiss: { vm?.showSolutionConfirm = false }
                    )
                }

                if showHintConfirm {
                    GameDialog(
                        title: "Use a hint?",
                        message: "Highlights a word clue and its location on the grid.",
                        primaryLabel: "Show hint",
                        primaryIsDestructive: false,
                        primaryAction: {
                            showHintConfirm = false
                            vm?.applyHint()
                        },
                        dismissLabel: "Cancel",
                        onDismiss: { showHintConfirm = false }
                    )
                }

                if vm!.showKeepTrying {
                    GameDialog(
                        title: "Not quite!",
                        message: "All blocks are placed but some words aren't right. Check the highlighted slots and try rearranging.",
                        dismissLabel: "Keep trying",
                        onDismiss: { vm?.showKeepTrying = false }
                    )
                }

                if tappedClueSlotId != nil {
                    GameDialog(
                        title: "Clue \(tappedClueNum.map { String($0) } ?? "")",
                        message: vm!.puzzle.clues[tappedClueSlotId!] ?? "",
                        dismissLabel: "Got it",
                        onDismiss: { tappedClueSlotId = nil; tappedClueNum = nil }
                    )
                }
            } else {
                // Loading state
                VStack(spacing: 0) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.eqText)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    Spacer()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.4)
                            .tint(.eqTextDim)
                        Text("Building puzzle…")
                            .font(.system(size: 14))
                            .foregroundColor(.eqTextDim)
                    }

                    Spacer()
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        zstackOrigin    = geo.frame(in: .global).origin
                        puzzleAreaWidth = min(geo.size.width, 680) - 120
                    }
                    .onChange(of: geo.frame(in: .global)) { _, frame in zstackOrigin = frame.origin }
                    .onChange(of: geo.size.width) { _, w in puzzleAreaWidth = w - 120 }
            }
        )
        .task {
            guard vm == nil else { return }
            await generatePuzzle()
            // Timer loop runs after puzzle is ready
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if vm?.timerRunning == true { vm?.elapsedSeconds += 1 }
            }
        }
        .onChange(of: vm?.showSolvedSheet) { _, showing in
            guard showing == true, let v = vm, !v.solutionWasShown else { return }
            if v.isPractice {
                store.recordUnlimitedSolve(difficulty: difficulty)
                store.clearUnlimitedSeed(for: difficulty)
            } else {
                store.recordSolve(difficulty: difficulty, seconds: v.elapsedSeconds)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive: vm?.pauseTimer()
            case .active:               vm?.resumeTimer()
            @unknown default: break
            }
        }
        .sheet(isPresented: Binding(
            get: { vm?.showSolvedSheet ?? false },
            set: { vm?.showSolvedSheet = $0 }
        )) {
            if let v = vm {
                SolvedSheetView(
                    difficulty: difficulty,
                    seconds: v.elapsedSeconds,
                    isPractice: v.isPractice,
                    isPersonalBest: !v.isPractice && isNewPersonalBest(),
                    onDone: { vm?.showSolvedSheet = false; onBack() },
                    onNextPuzzle: onNextPuzzle.map { next in { vm?.showSolvedSheet = false; next() } }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.eqBackground)
            }
        }
    }

    // MARK: - Async generation

    private func generatePuzzle() async {
        let alreadySolved = !isPractice && store.isCompletedToday(difficulty)
        let storedSec = !isPractice ? (store.dailyTimes[store.todayString()]?[difficulty.rawValue] ?? 0) : 0
        let isPractice = self.isPractice
        let practiceSeed = self.practiceSeed
        let difficulty = self.difficulty

        let data = await Task.detached(priority: .userInitiated) {
            if isPractice, let s = practiceSeed {
                return WordPuzzleGenerator.make(for: difficulty, seed: s)
            } else {
                return WordPuzzleGenerator.makeDaily(for: difficulty)
            }
        }.value

        vm = PuzzleState(
            difficulty: difficulty,
            isPractice: isPractice,
            startSolved: alreadySolved,
            solvedSeconds: storedSec,
            practiceSeed: practiceSeed,
            puzzleData: data
        )
    }

    // MARK: - Subviews

    @ViewBuilder
    private var dragOverlay: some View {
        if let vm = vm, let drag = vm.dragState {
            let block = vm.blocks[drag.blockId]
            let cs = vm.cellSize
            let gap = vm.gap
            let cellStep = cs + gap
            let totalW = CGFloat(block.cols) * cs + CGFloat(block.cols - 1) * gap
            let totalH = CGFloat(block.rows) * cs + CGFloat(block.rows - 1) * gap
            let cx = drag.currentLocation.x - zstackOrigin.x
            let cy = drag.currentLocation.y - zstackOrigin.y - totalH / 2
            BlockShapeView(block: block, cellSize: cs, isOverlay: true, gap: gap)
                .opacity(0.85)
                .position(x: cx, y: cy)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var flyingResetOverlay: some View {
        ForEach(flyingBlocks) { flying in
            BlockShapeView(block: flying.block, cellSize: flying.cellSize, isOverlay: false, gap: flying.gap)
                .opacity(flyingAnimating ? 0 : 0.9)
                .scaleEffect(flyingAnimating ? 0.15 : 1.0, anchor: .bottom)
                .offset(y: flyingAnimating ? 140 : 0)
                .position(x: flying.center.x, y: flying.center.y)
                .allowsHitTesting(false)
        }
    }

    private var topBar: some View {
        let vm = vm!
        return HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.eqText)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(vm.isPractice
                ? "\(difficulty.rawValue) · \(vm.shareCode ?? "Unlimited")"
                : "Daily · \(difficulty.rawValue)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.eqText)

            Spacer()

            HStack(spacing: 4) {
                Text(vm.timerDisplay)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.eqTextDim)
                    .frame(minWidth: 52, alignment: .trailing)

                Menu {
                    if let code = vm.shareCode {
                        let shareText = "Try this Writer's Block puzzle!\nCode: \(code)\n\nOpen Writer's Block → Unlimited → Enter Code"
                        ShareLink(item: shareText) {
                            Label("Share Puzzle", systemImage: "square.and.arrow.up")
                        }
                        Divider()
                    }
                    if vm.isPractice, let next = onNextPuzzle {
                        Button(action: next) {
                            Label("New Puzzle", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Divider()
                    }
                    if !vm.isSolved {
                        Button { showHintConfirm = true } label: {
                            Label("Hint", systemImage: "lightbulb.fill")
                        }
                        Divider()
                    }
                    Button { self.vm?.showSolutionConfirm = true } label: {
                        Label("Show Solution", systemImage: "lightbulb")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.eqTextDim)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 8)
    }

    private var solvedBanner: some View {
        let vm = vm!
        return HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.eqGreen)
            Text("Solved in \(vm.timerDisplay)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.eqText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.eqGreen.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.eqGreen.opacity(0.4), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
    }

    private var statusBar: some View {
        let vm = vm!
        let remaining = vm.blocks.filter { !$0.isPlaced }.count
        return Group {
            if vm.dragState != nil {
                Text("Drop to place · tap a placed letter to remove")
                    .font(.system(size: 12)).foregroundColor(.eqMuted)
            } else if remaining > 0 {
                Text("\(remaining) block\(remaining == 1 ? "" : "s") remaining · tap to rotate")
                    .font(.system(size: 12)).foregroundColor(.eqMuted)
            } else {
                Text("All blocks placed!")
                    .font(.system(size: 12)).foregroundColor(.eqGreen)
            }
        }
        .frame(height: 18)
    }

    private var resetButton: some View {
        Button(action: triggerReset) {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.eqTextDim)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.eqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.eqBorder, lineWidth: 1))
        }
    }

    // MARK: - Reset animation

    private func triggerReset() {
        guard let vm = vm else { return }
        guard vm.dragState == nil, flyingBlocks.isEmpty else { return }
        var blockMinRow: [Int: Int] = [:]
        var blockMinCol: [Int: Int] = [:]
        for (coord, cell) in vm.placedLetters {
            guard !cell.isAnchor, let blockId = cell.blockId else { continue }
            blockMinRow[blockId] = min(blockMinRow[blockId] ?? coord.row, coord.row)
            blockMinCol[blockId] = min(blockMinCol[blockId] ?? coord.col, coord.col)
        }
        let cs = vm.cellSize; let gap = vm.gap
        var snapped: [FlyingBlock] = []
        for blockId in blockMinRow.keys {
            guard blockId < vm.blocks.count,
                  let minRow = blockMinRow[blockId], let minCol = blockMinCol[blockId] else { continue }
            let block = vm.blocks[blockId]
            let w = CGFloat(block.cols) * cs + CGFloat(block.cols - 1) * gap
            let h = CGFloat(block.rows) * cs + CGFloat(block.rows - 1) * gap
            let gx = vm.gridOrigin.x + CGFloat(minCol) * (cs + gap)
            let gy = vm.gridOrigin.y + CGFloat(minRow) * (cs + gap)
            snapped.append(FlyingBlock(
                id: blockId, block: block,
                center: CGPoint(x: gx - zstackOrigin.x + w / 2, y: gy - zstackOrigin.y + h / 2),
                cellSize: cs, gap: gap
            ))
        }
        flyingBlocks = snapped
        flyingAnimating = false
        self.vm?.reset()
        withAnimation(.easeIn(duration: 0.28)) { flyingAnimating = true }
        Task {
            try? await Task.sleep(for: .milliseconds(320))
            flyingBlocks = []
            flyingAnimating = false
        }
    }

    private func isNewPersonalBest() -> Bool {
        guard let vm = vm, let best = store.personalBest(for: difficulty) else { return true }
        return vm.elapsedSeconds < best
    }
}

// MARK: - CluesPanelView

private struct CluesPanelView: View {
    let slots: [WordSlot]
    let clues: [Int: String]
    let hintedSlotId: Int?
    let onTap: (Int, Int) -> Void   // slotId, display number

    /// Slots sorted by start-cell position (top→bottom, left→right),
    /// across before down when starting at the same cell. Direction is
    /// intentionally NOT exposed to the player until a hint is used.
    private var orderedSlots: [WordSlot] {
        slots.sorted {
            let a = $0.cells[0], b = $1.cells[0]
            if a.row != b.row { return a.row < b.row }
            if a.col != b.col { return a.col < b.col }
            return $0.direction == .across
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Clues")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.eqTextDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.eqSurface)

            Divider().background(Color.eqBorder)

            HStack {
                Spacer()
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(36), spacing: 4), count: 5),
                    spacing: 4
                ) {
                    ForEach(Array(orderedSlots.enumerated()), id: \.element.id) { idx, slot in
                        clueButton(num: idx + 1, slot: slot)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.eqSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.eqBorder, lineWidth: 1))
    }

    @ViewBuilder
    private func clueButton(num: Int, slot: WordSlot) -> some View {
        let isHinted = slot.id == hintedSlotId
        Button { onTap(slot.id, num) } label: {
            Text("\(num)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isHinted ? .eqAmber : .eqTextDim)
                .frame(width: 36, height: 28)
                .background(isHinted ? Color.eqAmber.opacity(0.15) : Color.eqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isHinted ? Color.eqAmber : Color.eqBorder,
                            lineWidth: isHinted ? 2 : 1
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isHinted)
    }
}
