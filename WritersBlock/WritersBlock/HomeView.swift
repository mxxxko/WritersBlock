import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    let store: AppDataStore
    let storeManager: StoreManager
    let onSelectDifficulty: (Difficulty) -> Void
    let onStartUnlimited: (Difficulty) -> Void
    let onPlayCode: (Difficulty, Int) -> Void
    let onHowToPlay: () -> Void
    @Binding var weekBarsVisible: Bool

    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingCodeEntry = false
    @State private var codeInput = ""
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    dailyChallengesSection
                    unlimitedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 48)
                .frame(maxWidth: 520)
            }
        }
        .overlay(alignment: .topLeading) {
            Button(action: onHowToPlay) {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.eqTextDim)
                    .frame(width: 44, height: 44)
            }
            .padding(.top, 8)
            .padding(.leading, 4)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                isDarkMode.toggle()
            } label: {
                Image(systemName: isDarkMode ? "sun.max" : "moon")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.eqTextDim)
                    .frame(width: 44, height: 44)
            }
            .padding(.top, 8)
            .padding(.trailing, 4)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: storeManager)
                .presentationBackground(Color.eqBackground)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color.eqBackground, Color.eqSurfaceHigh],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Faint drifting letters
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Row 0
                    DriftingLetter("W",  x: 0.04*w, y: 0.02*h, size: 20, angle: -12, dx:  18, dy:  14, dur: 13)
                    DriftingLetter("O",  x: 0.18*w, y: 0.03*h, size: 30, angle:  -8, dx:  22, dy:  20, dur: 11)
                    DriftingLetter("R",  x: 0.35*w, y: 0.02*h, size: 24, angle:  15, dx: -18, dy:  24, dur: 15)
                    DriftingLetter("D",  x: 0.52*w, y: 0.04*h, size: 18, angle: -20, dx:  14, dy:  18, dur:  9)
                    DriftingLetter("S",  x: 0.68*w, y: 0.02*h, size: 28, angle:  10, dx: -24, dy:  16, dur: 14)
                    DriftingLetter("B",  x: 0.84*w, y: 0.03*h, size: 22, angle: -25, dx:  20, dy:  22, dur: 12)
                    DriftingLetter("L",  x: 0.95*w, y: 0.05*h, size: 16, angle:   5, dx: -14, dy:  18, dur: 16)

                    // Row 1
                    DriftingLetter("A",  x: 0.08*w, y: 0.11*h, size: 26, angle:  18, dx:  24, dy: -16, dur: 10)
                    DriftingLetter("C",  x: 0.26*w, y: 0.13*h, size: 34, angle: -10, dx: -20, dy:  22, dur: 17)
                    DriftingLetter("K",  x: 0.44*w, y: 0.10*h, size: 20, angle:   8, dx:  16, dy: -20, dur: 13)
                    DriftingLetter("E",  x: 0.60*w, y: 0.12*h, size: 28, angle: -15, dx: -28, dy:  14, dur:  8)
                    DriftingLetter("T",  x: 0.78*w, y: 0.11*h, size: 16, angle:  22, dx:  18, dy: -24, dur: 15)
                    DriftingLetter("P",  x: 0.92*w, y: 0.13*h, size: 30, angle:  -5, dx: -16, dy:  20, dur: 11)

                    // Row 2
                    DriftingLetter("U",  x: 0.03*w, y: 0.22*h, size: 32, angle: -18, dx:  26, dy:  18, dur: 14)
                    DriftingLetter("Z",  x: 0.20*w, y: 0.24*h, size: 18, angle:  12, dx: -22, dy: -16, dur:  9)
                    DriftingLetter("I",  x: 0.38*w, y: 0.21*h, size: 26, angle:  -8, dx:  20, dy:  24, dur: 16)
                    DriftingLetter("N",  x: 0.55*w, y: 0.23*h, size: 22, angle:  20, dx: -18, dy: -20, dur: 12)
                    DriftingLetter("G",  x: 0.72*w, y: 0.22*h, size: 30, angle: -12, dx:  24, dy:  16, dur: 10)
                    DriftingLetter("F",  x: 0.89*w, y: 0.24*h, size: 24, angle:   6, dx: -20, dy:  22, dur: 13)

                    // Row 3
                    DriftingLetter("H",  x: 0.12*w, y: 0.33*h, size: 18, angle:  25, dx:  16, dy: -18, dur: 15)
                    DriftingLetter("J",  x: 0.30*w, y: 0.35*h, size: 28, angle: -15, dx: -24, dy:  20, dur: 11)
                    DriftingLetter("M",  x: 0.48*w, y: 0.32*h, size: 36, angle:   9, dx:  22, dy: -26, dur:  8)
                    DriftingLetter("V",  x: 0.65*w, y: 0.34*h, size: 20, angle: -22, dx: -16, dy:  18, dur: 17)
                    DriftingLetter("X",  x: 0.82*w, y: 0.33*h, size: 26, angle:  14, dx:  28, dy: -14, dur: 12)

                    // Row 4
                    DriftingLetter("Q",  x: 0.06*w, y: 0.45*h, size: 30, angle: -10, dx:  20, dy:  22, dur: 14)
                    DriftingLetter("Y",  x: 0.23*w, y: 0.47*h, size: 16, angle:  18, dx: -18, dy: -24, dur: 10)
                    DriftingLetter("W",  x: 0.42*w, y: 0.44*h, size: 24, angle: -20, dx:  26, dy:  16, dur: 16)
                    DriftingLetter("O",  x: 0.58*w, y: 0.46*h, size: 32, angle:   5, dx: -22, dy: -18, dur:  9)
                    DriftingLetter("R",  x: 0.76*w, y: 0.45*h, size: 20, angle: -14, dx:  18, dy:  26, dur: 13)
                    DriftingLetter("D",  x: 0.93*w, y: 0.47*h, size: 28, angle:  20, dx: -24, dy: -20, dur: 11)

                    // Row 5
                    DriftingLetter("S",  x: 0.15*w, y: 0.56*h, size: 22, angle: -16, dx:  24, dy: -16, dur: 15)
                    DriftingLetter("B",  x: 0.33*w, y: 0.58*h, size: 30, angle:  10, dx: -20, dy:  22, dur: 12)
                    DriftingLetter("L",  x: 0.50*w, y: 0.55*h, size: 18, angle: -24, dx:  16, dy:  18, dur:  8)
                    DriftingLetter("A",  x: 0.68*w, y: 0.57*h, size: 34, angle:  12, dx: -28, dy: -14, dur: 17)
                    DriftingLetter("C",  x: 0.86*w, y: 0.56*h, size: 22, angle: -18, dx:  22, dy:  20, dur: 10)

                    // Row 6
                    DriftingLetter("K",  x: 0.04*w, y: 0.67*h, size: 26, angle:  20, dx:  18, dy: -22, dur: 13)
                    DriftingLetter("E",  x: 0.22*w, y: 0.69*h, size: 32, angle: -12, dx: -26, dy:  16, dur: 16)
                    DriftingLetter("T",  x: 0.40*w, y: 0.66*h, size: 20, angle:   8, dx:  20, dy:  24, dur: 11)
                    DriftingLetter("P",  x: 0.57*w, y: 0.68*h, size: 28, angle: -20, dx: -18, dy: -20, dur: 14)
                    DriftingLetter("U",  x: 0.74*w, y: 0.67*h, size: 16, angle:  15, dx:  24, dy:  18, dur:  9)
                    DriftingLetter("Z",  x: 0.91*w, y: 0.69*h, size: 30, angle: -10, dx: -20, dy: -24, dur: 12)

                    // Row 7
                    DriftingLetter("I",  x: 0.10*w, y: 0.78*h, size: 24, angle:  22, dx:  22, dy:  16, dur: 15)
                    DriftingLetter("N",  x: 0.28*w, y: 0.80*h, size: 28, angle: -18, dx: -16, dy: -20, dur:  8)
                    DriftingLetter("G",  x: 0.46*w, y: 0.77*h, size: 18, angle:  10, dx:  18, dy:  26, dur: 17)
                    DriftingLetter("F",  x: 0.63*w, y: 0.79*h, size: 34, angle: -14, dx: -24, dy:  14, dur: 10)
                    DriftingLetter("H",  x: 0.80*w, y: 0.78*h, size: 22, angle:  18, dx:  16, dy: -22, dur: 13)

                    // Row 8
                    DriftingLetter("J",  x: 0.05*w, y: 0.89*h, size: 28, angle: -22, dx:  20, dy: -16, dur: 11)
                    DriftingLetter("M",  x: 0.22*w, y: 0.91*h, size: 16, angle:  14, dx: -18, dy:  22, dur: 16)
                    DriftingLetter("V",  x: 0.39*w, y: 0.88*h, size: 32, angle:  -8, dx:  26, dy:  18, dur: 12)
                    DriftingLetter("X",  x: 0.56*w, y: 0.90*h, size: 20, angle:  20, dx: -22, dy: -16, dur:  9)
                    DriftingLetter("Q",  x: 0.73*w, y: 0.89*h, size: 26, angle: -15, dx:  18, dy:  20, dur: 14)
                    DriftingLetter("Y",  x: 0.89*w, y: 0.91*h, size: 22, angle:  10, dx: -16, dy: -18, dur: 15)
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Logo

    private var writersBlockLogo: some View {
        let font = Font.system(size: 42, weight: .heavy, design: .rounded)
        let faceGradient = LinearGradient(
            colors: [.eqBrandPurple, .eqBrandPurple.opacity(0.82)],
            startPoint: .top, endPoint: .bottom
        )
        let chars = Array("Writer's Block")

        return TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * 1.8
            HStack(spacing: -1) {
                ForEach(0..<chars.count, id: \.self) { i in
                    let waveY = sin(phase + Double(i) * 0.75) * 4.0
                    ZStack {
                        Text(String(chars[i])).font(font)
                            .foregroundStyle(Color.black.opacity(0.35))
                            .offset(x: 3, y: 4 + waveY)
                        Text(String(chars[i])).font(font)
                            .foregroundStyle(Color.eqBrandPurple.opacity(0.55))
                            .offset(x: 1.5, y: 2 + waveY)
                        Text(String(chars[i])).font(font)
                            .foregroundStyle(Color.white.opacity(0.60))
                            .offset(x: -1, y: -1 + waveY)
                        Text(String(chars[i])).font(font)
                            .foregroundStyle(faceGradient)
                            .offset(y: waveY)
                    }
                    .fixedSize()
                }
            }
        }
        .drawingGroup()
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            writersBlockLogo

            HStack(spacing: 10) {
                StreakBadgeView(streak: store.activeStreak)
                LifetimePuzzleCard(count: store.lifetimePuzzleCount)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
        }
    }

    private var dailyChallengesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "hourglass")
                    .font(.system(size: 11, weight: .semibold))
                Text("Daily Challenges")
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(1.2)
            }
            .foregroundColor(.eqTextDim)

            HStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyCardView(
                        difficulty: difficulty,
                        isCompleted: store.isCompletedToday(difficulty),
                        todayTime: store.dailyTimes[store.todayString()]?[difficulty.rawValue]
                    ) {
                        onSelectDifficulty(difficulty)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("This Week")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.eqTextDim)
                    .kerning(1.2)

                WeekDotsView(completions: store.completions, dailyTimes: store.dailyTimes, barsVisible: $weekBarsVisible)
            }
            .padding(.top, 6)
        }
    }

    private var unlimitedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "infinity")
                    .font(.system(size: 11, weight: .semibold))
                Text("Unlimited Mode")
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(1.2)
                if !storeManager.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.eqTextDim)

            HStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    UnlimitedCardView(
                        difficulty: difficulty,
                        solvedCount: store.unlimitedSolvedToday(for: difficulty),
                        onTap: {
                            if storeManager.isUnlocked { onStartUnlimited(difficulty) }
                            else { showPaywall = true }
                        }
                    )
                }
            }

            // Hint tokens row
            HintTokenRow(hintTokens: store.hintTokens)

            Button {
                if storeManager.isUnlocked { showingCodeEntry = true }
                else { showPaywall = true }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 11))
                    Text("Enter board code")
                        .font(.system(size: 13))
                }
                .foregroundColor(.eqTextDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color.eqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.eqBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .alert("Enter Puzzle Code", isPresented: $showingCodeEntry) {
            TextField("e.g. N394857", text: $codeInput)
                .textInputAutocapitalization(.characters)
            Button("Play") {
                if let (difficulty, seed) = parseCode(codeInput) {
                    onPlayCode(difficulty, seed)
                }
                codeInput = ""
            }
            Button("Cancel", role: .cancel) { codeInput = "" }
        } message: {
            Text("Enter the code your friend shared with you.")
        }
    }

    /// Parses "N394857" → (.normal, 394857) or "C394857" → (.challenging, 394857).
    private func parseCode(_ raw: String) -> (Difficulty, Int)? {
        let s = raw.trimmingCharacters(in: .whitespaces).uppercased()
        guard s.count >= 2, let seed = Int(s.dropFirst()), seed > 0 else { return nil }
        switch s.prefix(1) {
        case "E": return (.easy, seed)
        case "N": return (.normal, seed)
        case "H": return (.hard, seed)
        case "C": return (.challenging, seed)
        default:  return nil
        }
    }
}

// MARK: - DifficultyCardView

struct DifficultyCardView: View {
    let difficulty: Difficulty
    let isCompleted: Bool
    let todayTime: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(difficulty.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if isCompleted {
                        Text("✓")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(difficulty.color)
                    }
                }

                Text(todayTime.map { $0.formattedAsTime() } ?? "—")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(todayTime != nil ? .eqMuted : .eqMuted.opacity(0.5))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.eqSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isCompleted ? difficulty.color.opacity(0.5) : Color.eqBorder,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WeekDotsView

private struct SelectedDay: Identifiable {
    let id: String
    let date: Date
}

struct WeekDotsView: View {
    let completions: [String: Set<String>]
    let dailyTimes: [String: [String: Int]]
    @Binding var barsVisible: Bool

    @State private var selectedDay: SelectedDay? = nil

    private static let maxSolves = Difficulty.allCases.count
    private let barMaxHeight: CGFloat = 56
    private let barWidth:     CGFloat = 28

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let daysAgo  = 6 - i
                let date     = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
                let dateStr  = DateFormatter.isoDate.string(from: date)
                let solves   = solveCount(on: dateStr)
                let isToday  = daysAgo == 0
                let fillFrac = solves == 0 ? 0.0 : CGFloat(solves) / CGFloat(Self.maxSolves)

                VStack(spacing: 5) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.eqSurfaceHigh)
                            .frame(width: barWidth, height: barMaxHeight)

                        if solves > 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(
                                    colors: barGradientColors(solves: solves),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .frame(
                                    width: barWidth,
                                    height: barsVisible ? barMaxHeight * fillFrac : 0
                                )
                                .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(Double(i) * 0.06), value: barsVisible)
                        }

                        if isToday {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.eqAmber, lineWidth: 1.5)
                                .frame(width: barWidth, height: barMaxHeight)
                        }
                    }

                    Text(dayLabel(for: date))
                        .font(.system(size: isToday ? 13 : 10, weight: isToday ? .bold : .regular))
                        .foregroundColor(isToday ? .eqText : .eqMuted)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDay = SelectedDay(id: dateStr, date: date)
                }
            }
        }
        .onAppear { barsVisible = true }
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(date: day.date, times: dailyTimes[day.id] ?? [:])
                .presentationDetents([.height(320)])
                .presentationBackground(Color.eqBackground)
        }
    }

    private func solveCount(on dateString: String) -> Int {
        let raw = completions[dateString] ?? []
        return Difficulty.allCases.filter { raw.contains($0.rawValue) }.count
    }

    private func barGradientColors(solves: Int) -> [Color] {
        if solves >= Self.maxSolves {
            return [Color.eqAmber, Color.eqAmber.opacity(0.55)]
        } else {
            return [Color.eqGreen, Color.eqGreen.opacity(0.45)]
        }
    }

    private static let dayInitialFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()

    private func dayLabel(for date: Date) -> String {
        String(Self.dayInitialFormatter.string(from: date).prefix(1))
    }
}

// MARK: - DayDetailSheet

struct DayDetailSheet: View {
    let date: Date
    let times: [String: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(formattedDate)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.eqText)
                .padding(.top, 4)

            VStack(spacing: 0) {
                ForEach(Array(Difficulty.allCases.enumerated()), id: \.offset) { index, difficulty in
                    HStack {
                        Circle()
                            .fill(difficulty.color)
                            .frame(width: 8, height: 8)
                        Text(difficulty.rawValue)
                            .font(.system(size: 15))
                            .foregroundColor(.eqText)
                        Spacer()
                        if let seconds = times[difficulty.rawValue] {
                            Text(seconds.formattedAsTime())
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundColor(.eqTextDim)
                        } else {
                            Text("—")
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundColor(.eqMuted)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    if index < Difficulty.allCases.count - 1 {
                        Rectangle()
                            .fill(Color.eqBorder)
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.eqSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.eqBorder, lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        return f
    }()

    private var formattedDate: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return Self.monthDayFormatter.string(from: date)
    }
}

// MARK: - UnlimitedCardView

struct UnlimitedCardView: View {
    let difficulty: Difficulty
    let solvedCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(difficulty.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(difficulty.color)

                    Text("\(solvedCount) today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(difficulty.color.opacity(0.72))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(difficulty.color.opacity(0.45))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(difficulty.color.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(difficulty.color.opacity(0.38), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - HintTokenRow

struct HintTokenRow: View {
    let hintTokens: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundColor(.eqAmber)
            Text("\(hintTokens) hint \(hintTokens == 1 ? "token" : "tokens") available")
                .font(.system(size: 13))
                .foregroundColor(.eqTextDim)
            Spacer()
            Text("Earn +1 per unlimited solve")
                .font(.system(size: 11))
                .foregroundColor(.eqMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.eqAmber.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.eqAmber.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - LifetimePuzzleCard

struct LifetimePuzzleCard: View {
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("📝")
                .font(.system(size: 32))

            VStack(alignment: .center, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.eqText)
                Text("puzzles solved")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.eqTextDim)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.eqBrandPurple.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color.eqBrandPurple.opacity(0.40), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - PressScaleButtonStyle

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - StreakBadgeView

struct StreakBadgeView: View {
    let streak: Int

    @State private var flamePulse  = false
    @State private var flameWobble = false
    @State private var showConfetti = false

    private var isHot: Bool { streak >= 7 }
    private var isMilestone: Bool { [3, 7, 14, 21, 30, 50, 100].contains(streak) }

    var body: some View {
        ZStack {
            badge
            if showConfetti {
                confettiBurst.allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: isHot ? 0.55 : 1.1)
                .repeatForever(autoreverses: true)
            ) { flamePulse = true }

            withAnimation(
                .easeInOut(duration: 0.75)
                .repeatForever(autoreverses: true)
            ) { flameWobble = true }

            if isMilestone {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    showConfetti = false
                }
            }
        }
    }

    private var badge: some View {
        HStack(spacing: 10) {
            Text(streak == 0 ? "🥶" : "🔥")
                .font(.system(size: 32))
                .scaleEffect(flamePulse ? 1.08 : 0.94)
                .rotationEffect(.degrees(flameWobble ? 4 : -4))

            VStack(alignment: .center, spacing: 2) {
                Text("\(streak)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.eqText)
                Text("day streak")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.eqTextDim)
                if isMilestone {
                    Text("🎉 milestone!")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.eqAmber)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.eqAmber.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color.eqAmber.opacity(0.40), lineWidth: 1.5)
                )
        )
    }

    private var confettiBurst: some View {
        ZStack {
            ForEach(0..<StreakConfettiParticle.count, id: \.self) {
                StreakConfettiParticle(index: $0)
            }
        }
    }
}

// MARK: - StreakConfettiParticle

private struct StreakConfettiParticle: View {
    static let count = 20

    private static let configs: [(a: Double, d: CGFloat, s: CGFloat, c: Int, t: Double)] = [
        (  0, 70, 8, 0, 0.00), ( 18, 85, 6, 1, 0.04), ( 36, 65, 9, 2, 0.00),
        ( 54, 80, 5, 3, 0.07), ( 72, 75, 7, 4, 0.02), ( 90, 90, 6, 0, 0.05),
        (108, 70, 8, 1, 0.00), (126, 80, 5, 2, 0.08), (144, 60, 9, 3, 0.03),
        (162, 85, 7, 4, 0.06), (180, 70, 6, 0, 0.01), (198, 90, 8, 1, 0.05),
        (216, 65, 5, 2, 0.00), (234, 75, 7, 3, 0.09), (252, 90, 6, 4, 0.03),
        (270, 70, 8, 0, 0.06), (288, 80, 5, 1, 0.00), (306, 65, 9, 2, 0.04),
        (324, 75, 6, 3, 0.07), (342, 60, 7, 4, 0.02),
    ]

    private static let colors: [Color] = [.eqAmber, .eqGreen, .eqBrandPurple, .eqRed, .white]

    let index: Int
    @State private var active = false

    var body: some View {
        let cfg = Self.configs[index]
        let rad = cfg.a * .pi / 180
        RoundedRectangle(cornerRadius: 2)
            .fill(Self.colors[cfg.c])
            .frame(width: cfg.s, height: cfg.s * 0.55)
            .rotationEffect(.degrees(cfg.a + (active ? 200 : 0)))
            .offset(
                x: active ? cos(rad) * cfg.d : 0,
                y: active ? sin(rad) * cfg.d : 0
            )
            .opacity(active ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.85).delay(cfg.t)) {
                    active = true
                }
            }
    }
}

// MARK: - DriftingLetter

private struct DriftingLetter: View {
    let letter: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let angle: Double
    let dx: CGFloat
    let dy: CGFloat
    let dur: Double

    @State private var drifted = false
    @Environment(\.colorScheme) private var colorScheme

    init(_ letter: String, x: CGFloat, y: CGFloat, size: CGFloat,
         angle: Double, dx: CGFloat, dy: CGFloat, dur: Double) {
        self.letter = letter
        self.x = x; self.y = y
        self.size = size; self.angle = angle
        self.dx = dx; self.dy = dy; self.dur = dur
    }

    private var letterColor: Color {
        colorScheme == .dark
            ? Color(red: 0.55, green: 0.40, blue: 1.0).opacity(0.22)
            : Color(red: 0.45, green: 0.25, blue: 0.05).opacity(0.07)
    }

    var body: some View {
        Text(letter)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundColor(letterColor)
            .rotationEffect(.degrees(angle))
            .position(
                x: x + (drifted ? dx : 0),
                y: y + (drifted ? dy : 0)
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: dur)
                    .repeatForever(autoreverses: true)
                ) {
                    drifted = true
                }
            }
    }
}
