import Foundation

// MARK: - Claude API Service

final class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - Request / Response Types

    struct Message: Codable {
        let role: String      // "user" or "assistant"
        let content: String
    }

    private struct RequestBody: Codable {
        let model: String
        let maxTokens: Int
        let system: String
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case system, messages
        }
    }

    private struct ResponseBody: Codable {
        let content: [ContentBlock]?
        let stopReason: String?
        let error: APIErrorDetail?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
            case error
        }
    }

    private struct ContentBlock: Codable {
        let type: String
        let text: String?
    }

    private struct APIErrorDetail: Codable {
        let type: String?
        let message: String?
    }

    // MARK: - Send Message

    func sendMessage(
        systemPrompt: String,
        messages: [Message]
    ) async throws -> String {
        let apiKey = AppConfig.claudeAPIKey
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.noAPIKey
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body = RequestBody(
            model: "claude-sonnet-4-20250514",
            maxTokens: 1024,
            system: systemPrompt,
            messages: messages
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeAPIError.networkError("Invalid response")
        }

        guard (200..<300).contains(http.statusCode) else {
            // Try to extract error message
            if let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
               let errorMsg = decoded.error?.message {
                throw ClaudeAPIError.apiError(http.statusCode, errorMsg)
            }
            throw ClaudeAPIError.httpError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)

        guard let text = decoded.content?.first(where: { $0.type == "text" })?.text else {
            throw ClaudeAPIError.noContent
        }

        return text
    }
}

// MARK: - Error Types

enum ClaudeAPIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(String)
    case httpError(Int)
    case apiError(Int, String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Claude API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .httpError(let code):
            return "API error (HTTP \(code))"
        case .apiError(_, let msg):
            return msg
        case .noContent:
            return "Empty response from AI"
        }
    }
}
