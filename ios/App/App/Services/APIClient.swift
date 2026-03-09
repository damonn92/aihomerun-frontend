import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(Int, Data)
    case decodingError(Error)
    case qualityGateFailure(QualityError)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .networkError(let e): return e.localizedDescription
        case .httpError(let code, _): return "Server error (\(code))"
        case .decodingError(let e): return "Response parsing failed: \(e.localizedDescription)"
        case .qualityGateFailure(let qe): return qe.issues.map { $0.message }.joined(separator: "\n")
        }
    }
}

class APIClient {
    static let shared = APIClient()

    /// Shared session with explicit timeouts for API requests
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - Analyze Video

    func analyzeVideo(
        fileURL: URL,
        actionType: String,
        age: Int,
        token: String?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> AnalysisResult {
        let urlString = AppConfig.apiBaseURL + "/analyze"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let body = try buildMultipartBody(
            boundary: boundary,
            fileURL: fileURL,
            actionType: actionType,
            age: age
        )

        let (data, response) = try await uploadWithProgress(
            request: request,
            body: body,
            progressHandler: progressHandler
        )

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 422 {
            // FastAPI wraps HTTPException detail in {"detail": {...}}.
            // Unwrap that envelope before decoding QualityError.
            struct FastAPIEnvelope: Decodable {
                struct Detail: Decodable {
                    let error: String
                    let issues: [QualityIssue]
                    let visibilityRate: Double?
                    enum CodingKeys: String, CodingKey {
                        case error, issues
                        case visibilityRate = "visibility_rate"
                    }
                }
                let detail: Detail
            }
            if let envelope = try? JSONDecoder().decode(FastAPIEnvelope.self, from: data) {
                let d = envelope.detail
                throw APIError.qualityGateFailure(
                    QualityError(error: d.error, issues: d.issues, visibilityRate: d.visibilityRate)
                )
            }
            // Fallback: try decoding QualityError directly (no envelope)
            if let qe = try? JSONDecoder().decode(QualityError.self, from: data) {
                throw APIError.qualityGateFailure(qe)
            }
            throw APIError.httpError(422, data)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode, data)
        }

        do {
            return try JSONDecoder().decode(AnalysisResult.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - History

    func fetchHistory(token: String?) async throws -> [SessionSummary] {
        let urlString = AppConfig.apiBaseURL + "/history?limit=20"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, data)
        }

        struct HistoryResponse: Decodable { let history: [SessionSummary] }
        return try JSONDecoder().decode(HistoryResponse.self, from: data).history
    }

    // MARK: - Helpers

    private func buildMultipartBody(
        boundary: String,
        fileURL: URL,
        actionType: String,
        age: Int
    ) throws -> Data {
        var body = Data()
        let crlf = "\r\n"

        func append(_ string: String) {
            body.append(Data(string.utf8))
        }

        // action_type field
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"action_type\"\(crlf)\(crlf)")
        append("\(actionType)\(crlf)")

        // age field
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"age\"\(crlf)\(crlf)")
        append("\(age)\(crlf)")

        // file field
        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let mimeType = filename.hasSuffix(".mov") ? "video/quicktime" : "video/mp4"
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\(crlf)")
        append("Content-Type: \(mimeType)\(crlf)\(crlf)")
        body.append(fileData)
        append(crlf)

        append("--\(boundary)--\(crlf)")
        return body
    }

    private func uploadWithProgress(
        request: URLRequest,
        body: Data,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = UploadDelegate(totalBytes: Int64(body.count), progressHandler: progressHandler) { result in
                continuation.resume(with: result)
            }
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 600
            let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            let task = session.uploadTask(with: request, from: body)
            delegate.task = task
            task.resume()
        }
    }
}

private class UploadDelegate: NSObject, URLSessionDataDelegate {
    let totalBytes: Int64
    let progressHandler: (Double) -> Void
    let completion: (Result<(Data, URLResponse), Error>) -> Void
    var accumulatedData = Data()
    var task: URLSessionUploadTask?
    var response: URLResponse?

    init(totalBytes: Int64, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        self.totalBytes = totalBytes
        self.progressHandler = progressHandler
        self.completion = completion
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(max(totalBytesExpectedToSend, 1))
        DispatchQueue.main.async { self.progressHandler(progress * 0.4) } // upload = first 40%
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        accumulatedData.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            completion(.failure(APIError.networkError(error)))
        } else if let response {
            completion(.success((accumulatedData, response)))
        }
    }
}
