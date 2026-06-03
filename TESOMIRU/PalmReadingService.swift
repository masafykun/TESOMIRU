import UIKit

// MARK: - Models

struct PalmReadingResult: Identifiable, Equatable {
    let id: UUID
    let summary: String
    let lines: [LineReading]
    let luckyColor: String
    let luckyNumber: Int

    init(
        id: UUID = UUID(),
        summary: String,
        lines: [LineReading],
        luckyColor: String,
        luckyNumber: Int
    ) {
        self.id = id
        self.summary = summary
        self.lines = lines
        self.luckyColor = luckyColor
        self.luckyNumber = luckyNumber
    }

    static func == (lhs: PalmReadingResult, rhs: PalmReadingResult) -> Bool {
        lhs.id == rhs.id
    }

    struct LineReading: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let iconColor: UIColor
        let description: String
        let score: Int

        init(name: String, description: String, score: Int) {
            self.name = name
            self.description = description
            self.score = max(1, min(5, score))
            let meta = Self.iconMeta(for: name)
            self.icon = meta.icon
            self.iconColor = meta.color
        }

        static func iconMeta(for name: String) -> (icon: String, color: UIColor) {
            switch name {
            case "生命線": return ("heart.fill", .systemRed)
            case "感情線": return ("waveform.path.ecg", .systemBlue)
            case "頭脳線": return ("lightbulb.fill", .systemGreen)
            case "運命線": return ("star.fill", .systemYellow)
            default:       return ("circle.fill", .systemPurple)
            }
        }
    }
}

// MARK: - Chat Models

struct PalmChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let date: Date

    init(id: UUID = UUID(), role: Role, content: String, date: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.date = date
    }

    enum Role: String, Codable {
        case user
        case assistant
    }
}

// MARK: - Errors

enum PalmReadingError: LocalizedError {
    case invalidImage
    case serverError(Int, String)
    case networkError(Error)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidImage:                  return "画像の変換に失敗しました"
        case .serverError(_, let message):   return message
        case .networkError(let e):           return "通信エラー: \(e.localizedDescription)"
        case .decodingError:                 return "レスポンスの解析に失敗しました"
        }
    }
}

// MARK: - Service

final class PalmReadingService {
    static let shared = PalmReadingService()
    private init() {}

    private let analyzeURL = URL(string: Config.analyzeAPIURL)!
    private let chatURL = URL(string: Config.chatAPIURL)!

    func analyze(image: UIImage) async throws -> PalmReadingResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PalmReadingError.invalidImage
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: analyzeURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipart(data: imageData, boundary: boundary, fieldName: "image", filename: "palm.jpg", mimeType: "image/jpeg")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PalmReadingError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
                ?? "サーバーエラーが発生しました (コード: \(code))"
            throw PalmReadingError.serverError(code, message)
        }

        return try decodeResponse(data)
    }

    /// 鑑定結果について追加質問する
    func chat(reading: PalmReadingResult, history: [PalmChatMessage], message: String) async throws -> String {
        struct ChatRequestLine: Encodable {
            let name: String
            let description: String
            let score: Int
        }
        struct ChatRequestReading: Encodable {
            let summary: String
            let lines: [ChatRequestLine]
            let luckyColor: String
            let luckyNumber: Int
        }
        struct ChatRequestMessage: Encodable {
            let role: String
            let content: String
        }
        struct ChatRequest: Encodable {
            let reading: ChatRequestReading
            let history: [ChatRequestMessage]
            let message: String
        }

        let body = ChatRequest(
            reading: ChatRequestReading(
                summary: reading.summary,
                lines: reading.lines.map { ChatRequestLine(name: $0.name, description: $0.description, score: $0.score) },
                luckyColor: reading.luckyColor,
                luckyNumber: reading.luckyNumber
            ),
            history: history.map { ChatRequestMessage(role: $0.role.rawValue, content: $0.content) },
            message: message
        )

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 60

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PalmReadingError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
                ?? "サーバーエラーが発生しました (コード: \(code))"
            throw PalmReadingError.serverError(code, message)
        }

        struct ChatResponse: Decodable { let reply: String }
        guard let res = try? JSONDecoder().decode(ChatResponse.self, from: data) else {
            throw PalmReadingError.decodingError
        }
        return res.reply
    }

    // MARK: - Private helpers

    private func buildMultipart(data: Data, boundary: String, fieldName: String, filename: String, mimeType: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        body.append("--\(boundary)\(crlf)".utf8Data)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\(crlf)".utf8Data)
        body.append("Content-Type: \(mimeType)\(crlf)\(crlf)".utf8Data)
        body.append(data)
        body.append("\(crlf)--\(boundary)--\(crlf)".utf8Data)
        return body
    }

    private func decodeResponse(_ data: Data) throws -> PalmReadingResult {
        struct Response: Decodable {
            let summary: String
            let lines: [Line]
            let luckyColor: String
            let luckyNumber: Int

            struct Line: Decodable {
                let name: String
                let description: String
                let score: Int
            }
        }

        guard let res = try? JSONDecoder().decode(Response.self, from: data) else {
            throw PalmReadingError.decodingError
        }

        return PalmReadingResult(
            summary: res.summary,
            lines: res.lines.map {
                PalmReadingResult.LineReading(name: $0.name, description: $0.description, score: $0.score)
            },
            luckyColor: res.luckyColor,
            luckyNumber: res.luckyNumber
        )
    }
}

private extension String {
    var utf8Data: Data { Data(utf8) }
}
