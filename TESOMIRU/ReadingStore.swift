import Foundation
import Combine

/// 過去の鑑定結果と各鑑定に紐づくチャット履歴を永続化する
@MainActor
final class ReadingStore: ObservableObject {
    static let shared = ReadingStore()

    @Published private(set) var readings: [SavedReading] = []

    /// 1日に無料で利用可能な鑑定回数
    static let freeDailyReadingLimit = 2

    private let defaultsKey = "tesomiru.savedReadings.v1"
    private let dailyCountKey = "tesomiru.dailyReadingCount.v1"
    private let dailyDateKey = "tesomiru.dailyReadingDate.v1"
    private let maxReadings = 50

    init() {
        load()
    }

    // MARK: - Daily limit

    /// 本日鑑定した回数
    var todayReadingCount: Int {
        let calendar = Calendar.current
        if let savedDate = UserDefaults.standard.object(forKey: dailyDateKey) as? Date,
           calendar.isDateInToday(savedDate) {
            return UserDefaults.standard.integer(forKey: dailyCountKey)
        }
        return 0
    }

    /// 鑑定を1回実行できるか（プレミアム会員は常にtrue）
    func canPerformReading(isPremium: Bool) -> Bool {
        isPremium || todayReadingCount < Self.freeDailyReadingLimit
    }

    /// 本日の鑑定回数を1増やす
    func incrementTodayReadingCount() {
        let calendar = Calendar.current
        let today = Date()
        let currentCount: Int
        if let savedDate = UserDefaults.standard.object(forKey: dailyDateKey) as? Date,
           calendar.isDateInToday(savedDate) {
            currentCount = UserDefaults.standard.integer(forKey: dailyCountKey)
        } else {
            currentCount = 0
        }
        UserDefaults.standard.set(currentCount + 1, forKey: dailyCountKey)
        UserDefaults.standard.set(today, forKey: dailyDateKey)
        objectWillChange.send()
    }

    // MARK: - Public

    func save(reading: PalmReadingResult) -> SavedReading {
        let saved = SavedReading(
            id: reading.id,
            date: Date(),
            summary: reading.summary,
            lines: reading.lines.map {
                SavedReading.Line(name: $0.name, description: $0.description, score: $0.score)
            },
            luckyColor: reading.luckyColor,
            luckyNumber: reading.luckyNumber,
            chatMessages: []
        )
        readings.insert(saved, at: 0)
        if readings.count > maxReadings {
            readings = Array(readings.prefix(maxReadings))
        }
        persist()
        return saved
    }

    func appendChat(to readingId: UUID, message: PalmChatMessage) {
        guard let idx = readings.firstIndex(where: { $0.id == readingId }) else { return }
        readings[idx].chatMessages.append(message)
        persist()
    }

    func delete(readingId: UUID) {
        readings.removeAll { $0.id == readingId }
        persist()
    }

    func clearAll() {
        readings.removeAll()
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([SavedReading].self, from: data) {
            readings = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(readings) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}

// MARK: - SavedReading

struct SavedReading: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let summary: String
    var lines: [Line]
    let luckyColor: String
    let luckyNumber: Int
    var chatMessages: [PalmChatMessage]

    struct Line: Codable, Equatable {
        let name: String
        let description: String
        let score: Int
    }

    /// SavedReading から PalmReadingResult を再構築する（UI表示時の利便のため）
    func toResult() -> PalmReadingResult {
        PalmReadingResult(
            id: id,
            summary: summary,
            lines: lines.map { PalmReadingResult.LineReading(name: $0.name, description: $0.description, score: $0.score) },
            luckyColor: luckyColor,
            luckyNumber: luckyNumber
        )
    }
}
