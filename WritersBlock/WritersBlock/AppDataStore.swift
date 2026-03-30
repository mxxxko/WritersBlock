import Foundation
import Observation

@Observable
final class AppDataStore {
    static let shared = AppDataStore()

    var personalBests: [String: Int] = [:]
    var completions: [String: Set<String>] = [:]
    var dailyTimes: [String: [String: Int]] = [:]
    var currentStreak: Int = 0
    var lastPlayedDate: String = ""
    var unlimitedCounts: [String: Int] = [:]
    var unlimitedCountsByDifficulty: [String: [String: Int]] = [:]
    var unlimitedCurrentSeeds: [String: Int] = [:]
    var hintTokens: Int = 3

    private let storageKey = "WritersBlockData_v1"

    private init() { load() }

    // MARK: - Queries

    func isCompletedToday(_ difficulty: Difficulty) -> Bool {
        completions[todayString()]?.contains(difficulty.rawValue) ?? false
    }

    func personalBest(for difficulty: Difficulty) -> Int? {
        personalBests[difficulty.rawValue]
    }

    func solvedCount(on dateString: String) -> Int {
        completions[dateString]?.count ?? 0
    }

    var activeStreak: Int {
        guard lastPlayedDate == todayString() || lastPlayedDate == yesterdayString() else { return 0 }
        return currentStreak
    }

    var lifetimePuzzleCount: Int {
        let daily = completions.values.reduce(0) { $0 + $1.count }
        let unlimited = unlimitedCounts.values.reduce(0, +)
        return daily + unlimited
    }

    func unlimitedSolvedToday(for difficulty: Difficulty) -> Int {
        unlimitedCountsByDifficulty[todayString()]?[difficulty.rawValue] ?? 0
    }

    func currentUnlimitedSeed(for difficulty: Difficulty) -> Int? {
        unlimitedCurrentSeeds[difficulty.rawValue]
    }

    // MARK: - Mutations

    func recordSolve(difficulty: Difficulty, seconds: Int) {
        let today = todayString()
        let current = personalBests[difficulty.rawValue]
        if current == nil || seconds < current! {
            personalBests[difficulty.rawValue] = seconds
        }
        var set = completions[today] ?? []
        set.insert(difficulty.rawValue)
        completions[today] = set
        dailyTimes[today, default: [:]][difficulty.rawValue] = seconds
        advanceStreak(today: today)
        save()
    }

    func recordUnlimitedSolve(difficulty: Difficulty) {
        let today = todayString()
        unlimitedCounts[today, default: 0] += 1
        unlimitedCountsByDifficulty[today, default: [:]][difficulty.rawValue, default: 0] += 1
        advanceStreak(today: today)
        // Earn a hint token (max 5)
        hintTokens = min(5, hintTokens + 1)
        save()
    }

    func setUnlimitedSeed(_ seed: Int, for difficulty: Difficulty) {
        unlimitedCurrentSeeds[difficulty.rawValue] = seed
        save()
    }

    func clearUnlimitedSeed(for difficulty: Difficulty) {
        unlimitedCurrentSeeds.removeValue(forKey: difficulty.rawValue)
        save()
    }

    func useHint() -> Bool {
        guard hintTokens > 0 else { return false }
        hintTokens -= 1
        save()
        return true
    }

    // MARK: - Helpers

    private func advanceStreak(today: String) {
        if lastPlayedDate == yesterdayString() {
            currentStreak += 1
        } else if lastPlayedDate != today {
            currentStreak = 1
        }
        lastPlayedDate = today
    }

    func todayString() -> String { DateFormatter.isoDate.string(from: Date()) }

    func yesterdayString() -> String {
        let d = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return DateFormatter.isoDate.string(from: d)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(Stored.self, from: data) else { return }
        personalBests    = decoded.personalBests
        completions      = decoded.completions.mapValues { Set($0) }
        dailyTimes       = decoded.dailyTimes ?? [:]
        currentStreak    = decoded.currentStreak
        lastPlayedDate   = decoded.lastPlayedDate
        unlimitedCounts  = decoded.unlimitedCounts ?? [:]
        unlimitedCountsByDifficulty = decoded.unlimitedCountsByDifficulty ?? [:]
        unlimitedCurrentSeeds       = decoded.unlimitedCurrentSeeds ?? [:]
        hintTokens       = decoded.hintTokens ?? 3
    }

    private func save() {
        let stored = Stored(
            personalBests:   personalBests,
            completions:     completions.mapValues { Array($0) },
            dailyTimes:      dailyTimes,
            currentStreak:   currentStreak,
            lastPlayedDate:  lastPlayedDate,
            unlimitedCounts: unlimitedCounts,
            unlimitedCountsByDifficulty: unlimitedCountsByDifficulty,
            unlimitedCurrentSeeds:       unlimitedCurrentSeeds,
            hintTokens:      hintTokens
        )
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private struct Stored: Codable {
        var personalBests:   [String: Int]
        var completions:     [String: [String]]
        var dailyTimes:      [String: [String: Int]]?
        var currentStreak:   Int
        var lastPlayedDate:  String
        var unlimitedCounts: [String: Int]?
        var unlimitedCountsByDifficulty: [String: [String: Int]]?
        var unlimitedCurrentSeeds: [String: Int]?
        var hintTokens: Int?
    }
}

extension DateFormatter {
    nonisolated static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
