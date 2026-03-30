import SwiftUI

private enum Route: Equatable {
    case daily(Difficulty)
    case unlimited(Difficulty, Int)   // Int = seed
    case howToPlay
}

struct RootNavigationView: View {
    let store: AppDataStore
    let storeManager: StoreManager
    @State private var route: Route? = nil
    @State private var weekBarsVisible = false

    var body: some View {
        ZStack {
            switch route {
            case .daily(let difficulty):
                PuzzleView(difficulty: difficulty, store: store) {
                    withAnimation(.easeInOut(duration: 0.3)) { route = nil }
                }
                .transition(.move(edge: .trailing))

            case .unlimited(let difficulty, let seed):
                PuzzleView(
                    difficulty: difficulty, store: store,
                    isPractice: true, practiceSeed: seed,
                    onBack: { withAnimation(.easeInOut(duration: 0.3)) { route = nil } },
                    onNextPuzzle: {
                        let newSeed = Int.random(in: 100_000...999_999)
                        store.setUnlimitedSeed(newSeed, for: difficulty)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            route = .unlimited(difficulty, newSeed)
                        }
                    }
                )
                .id(seed)
                .transition(.move(edge: .trailing))

            case .howToPlay:
                HowToPlayView(onBack: {
                    withAnimation(.easeInOut(duration: 0.3)) { route = nil }
                })
                .transition(.move(edge: .trailing))

            case nil:
                HomeView(
                    store: store,
                    storeManager: storeManager,
                    onSelectDifficulty: { d in
                        withAnimation(.easeInOut(duration: 0.3)) { route = .daily(d) }
                    },
                    onStartUnlimited: { d in
                        let seed = store.currentUnlimitedSeed(for: d) ?? {
                            let s = Int.random(in: 100_000...999_999)
                            store.setUnlimitedSeed(s, for: d)
                            return s
                        }()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            route = .unlimited(d, seed)
                        }
                    },
                    onPlayCode: { d, seed in
                        store.setUnlimitedSeed(seed, for: d)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            route = .unlimited(d, seed)
                        }
                    },
                    onHowToPlay: {
                        withAnimation(.easeInOut(duration: 0.3)) { route = .howToPlay }
                    },
                    weekBarsVisible: $weekBarsVisible
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: route)
    }
}
