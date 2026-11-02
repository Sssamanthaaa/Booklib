import Foundation

/// Streak and weekly maths, ported from the web app.
enum ReadingStats {
    struct Day: Identifiable {
        let id: Date
        let letter: String
        let minutes: Int
        let isRest: Bool        // a single missed day between two reading days
        var didRead: Bool { minutes > 0 }
    }

    private static let cal = Calendar.current

    static func minutes(on day: Date, _ sessions: [ReadingSession]) -> Int {
        sessions.filter { cal.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.minutes }
    }

    /// Forgiving streak: one missed day in a row is a "rest day" and does not break it.
    static func streak(_ sessions: [ReadingSession], now: Date = .now) -> Int {
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) })
        var day = cal.startOfDay(for: now)
        var count = days.contains(day) ? 1 : 0
        var gap = 0
        for _ in 1..<400 {
            day = cal.date(byAdding: .day, value: -1, to: day)!
            if days.contains(day) { count += 1; gap = 0 }
            else { gap += 1; if gap >= 2 { break } }
        }
        return count
    }

    /// Last 7 days, oldest first.
    static func week(_ sessions: [ReadingSession], now: Date = .now) -> [Day] {
        let today = cal.startOfDay(for: now)
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        return (0..<7).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: today)!
            let m = minutes(on: d, sessions)
            let prev = minutes(on: cal.date(byAdding: .day, value: -1, to: d)!, sessions) > 0
            let next = offset > 0 && minutes(on: cal.date(byAdding: .day, value: 1, to: d)!, sessions) > 0
            let weekday = cal.component(.weekday, from: d) - 1
            return Day(id: d, letter: letters[weekday], minutes: m, isRest: m == 0 && prev && next)
        }
    }

    static func totalMinutes(_ sessions: [ReadingSession]) -> Int { sessions.reduce(0) { $0 + $1.minutes } }
    static func totalPages(_ sessions: [ReadingSession]) -> Int { sessions.reduce(0) { $0 + max(0, $1.toPage - $1.fromPage) } }
}

/// Deterministic hash. Swift's built-in hashValue changes every launch, which would reshuffle spine styles.
enum StableHash {
    static func of(_ s: String) -> Int {
        var h: UInt32 = 7
        for u in s.unicodeScalars { h = h &* 31 &+ u.value }
        return Int(h)
    }
}
