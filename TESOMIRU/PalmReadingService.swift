import UIKit

// MARK: - Models

struct PalmReadingResult: Identifiable, Equatable {
    let id = UUID()
    let summary: String
    let lines: [LineReading]
    let luckyColor: String
    let luckyNumber: Int

    static func == (lhs: PalmReadingResult, rhs: PalmReadingResult) -> Bool {
        lhs.id == rhs.id
    }

    struct LineReading: Identifiable {
        let id = UUID()
        let name: String
        let icon: String   // SF Symbol name
        let iconColor: UIColor
        let description: String
        let score: Int     // 1-5
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

    private let serverURL = URL(string: "https://YOUR_API_SERVER/api/palm-reading")!

    /// 実際のサーバーに画像を送り、手相鑑定結果を取得する
    func analyze(image: UIImage) async throws -> PalmReadingResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PalmReadingError.invalidImage
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: serverURL)
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

    // MARK: - Mock（サーバー準備前の開発用）

    func analyzeMock(image: UIImage) async throws -> PalmReadingResult {
        // 実際の通信を模倣して3秒待つ
        try await Task.sleep(for: .seconds(3))

        return PalmReadingResult(
            summary: "あなたの手相は非常にバランスが取れています。知性と感情の調和が見事で、人生において多くの成功を収めるでしょう。特に対人関係での運が強く、周囲の人々に恵まれた充実した生涯を送ることが期待されます。直感力も優れており、大切な局面での判断力は人一倍です。",
            lines: [
                .init(
                    name: "生命線",
                    icon: "heart.fill",
                    iconColor: .systemRed,
                    description: "力強く長い生命線で、生命力と活力に満ちています。大きな困難にも屈せず、長寿と健康に恵まれるでしょう。中年以降もエネルギッシュに活躍できる暗示があります。",
                    score: 5
                ),
                .init(
                    name: "感情線",
                    icon: "waveform.path.ecg",
                    iconColor: .systemBlue,
                    description: "深く鮮明な感情線は、豊かな感受性と深い愛情を示しています。人間関係において誠実で信頼される存在です。恋愛運も強く、真剣な愛情を築けるでしょう。",
                    score: 4
                ),
                .init(
                    name: "頭脳線",
                    icon: "lightbulb.fill",
                    iconColor: .systemGreen,
                    description: "明瞭で長い頭脳線は、優れた知性と分析力を示しています。論理的思考と創造性のバランスが取れており、多彩なアイデアを実現できる力があります。",
                    score: 4
                ),
                .init(
                    name: "運命線",
                    icon: "star.fill",
                    iconColor: .systemYellow,
                    description: "はっきりとした運命線が手のひらの中央を走り、強い意志と明確な人生目標を持っていることを示しています。キャリアや使命において大きな成果を上げるでしょう。",
                    score: 5
                ),
            ],
            luckyColor: "紫",
            luckyNumber: 7
        )
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

        let iconMap: [String: (icon: String, color: UIColor)] = [
            "生命線": ("heart.fill", .systemRed),
            "感情線": ("waveform.path.ecg", .systemBlue),
            "頭脳線": ("lightbulb.fill", .systemGreen),
            "運命線": ("star.fill", .systemYellow),
        ]

        return PalmReadingResult(
            summary: res.summary,
            lines: res.lines.map { line in
                let meta = iconMap[line.name] ?? ("circle.fill", .systemPurple)
                return PalmReadingResult.LineReading(
                    name: line.name,
                    icon: meta.icon,
                    iconColor: meta.color,
                    description: line.description,
                    score: max(1, min(5, line.score))
                )
            },
            luckyColor: res.luckyColor,
            luckyNumber: res.luckyNumber
        )
    }
}

private extension String {
    var utf8Data: Data { Data(utf8) }
}
