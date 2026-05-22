//
//  CloudflareService.swift
//  VibeRite
//

import Foundation

enum CloudflareServiceError: LocalizedError {
    case notConfigured
    case invalidResponse
    case apiError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloudflare is not configured. Add your account ID and API token in settings."
        case .invalidResponse:
            return "Received an unexpected response from Cloudflare."
        case .apiError(let message):
            return message
        case .networkError(let message):
            return "Could not reach Cloudflare: \(message)"
        }
    }
}

/// Talks to Cloudflare Workers AI over HTTPS.
actor CloudflareService {
    static let shared = CloudflareService()

    private let session: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
    }

    func isConfigured(accountID: String, apiToken: String) -> Bool {
        !accountID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func generate(
        prompt: String,
        system: String? = nil,
        model: CloudflareModel,
        accountID: String,
        apiToken: String,
        stream: Bool = true,
        onPartial: (@Sendable (String) -> Void)? = nil
    ) async throws -> String {
        guard isConfigured(accountID: accountID, apiToken: apiToken) else {
            throw CloudflareServiceError.notConfigured
        }

        let trimmedAccountID = accountID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = runURL(accountID: trimmedAccountID, model: model) else {
            throw CloudflareServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedToken)", forHTTPHeaderField: "Authorization")

        var messages: [CloudflareChatMessage] = []
        if let system, !system.isEmpty {
            messages.append(.init(role: "system", content: system))
        }
        messages.append(.init(role: "user", content: prompt))

        let body = CloudflareRunRequest(messages: messages, stream: stream)
        request.httpBody = try JSONEncoder().encode(body)

        if stream {
            return try await generateStreaming(request: request, onPartial: onPartial)
        }

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response)

        let envelope = try decoder.decode(CloudflareEnvelope.self, from: data)
        try throwIfNeeded(envelope)

        guard let text = envelope.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw CloudflareServiceError.invalidResponse
        }

        onPartial?(text)
        return text
    }

    private func generateStreaming(
        request: URLRequest,
        onPartial: (@Sendable (String) -> Void)?
    ) async throws -> String {
        let (bytes, response) = try await session.bytes(for: request)
        try validateHTTP(response)

        var fullText = ""

        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }

            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            guard !payload.isEmpty, payload != "[DONE]" else { continue }
            guard let data = payload.data(using: .utf8) else { continue }

            let event = try decoder.decode(CloudflareStreamEvent.self, from: data)
            try throwIfNeeded(event)

            if let piece = event.textDelta, !piece.isEmpty {
                fullText += piece
                onPartial?(fullText)
            }
        }

        let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CloudflareServiceError.invalidResponse
        }

        return trimmed
    }

    private func runURL(accountID: String, model: CloudflareModel) -> URL? {
        let trimmedAccountID = accountID.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedModel = model.rawValue.replacingOccurrences(of: "@", with: "%40")
        return URL(string: "https://api.cloudflare.com/client/v4/accounts/\(trimmedAccountID)/ai/run/\(encodedModel)")
    }

    private func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw CloudflareServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw CloudflareServiceError.networkError("HTTP \(http.statusCode)")
        }
    }

    private func throwIfNeeded(_ envelope: CloudflareEnvelope) throws {
        if envelope.success == false {
            let message = envelope.errors?.compactMap(\.message).joined(separator: ", ")
            throw CloudflareServiceError.apiError(message?.isEmpty == false ? message! : "Cloudflare request failed.")
        }
    }

    private func throwIfNeeded(_ event: CloudflareStreamEvent) throws {
        if event.success == false {
            let message = event.errors?.compactMap(\.message).joined(separator: ", ")
            throw CloudflareServiceError.apiError(message?.isEmpty == false ? message! : "Cloudflare request failed.")
        }
    }
}

private struct CloudflareRunRequest: Encodable {
    let messages: [CloudflareChatMessage]
    let stream: Bool
    let maxTokens: Int = 2048
    let temperature: Double = 0.2

    enum CodingKeys: String, CodingKey {
        case messages
        case stream
        case maxTokens = "max_tokens"
        case temperature
    }
}

private struct CloudflareChatMessage: Encodable {
    let role: String
    let content: String
}

private struct CloudflareEnvelope: Decodable {
    let success: Bool?
    let errors: [CloudflareAPIError]?
    let result: CloudflareResult?

    var text: String? {
        result?.response
    }
}

private struct CloudflareAPIError: Decodable {
    let message: String?
}

private struct CloudflareResult: Decodable {
    let response: String?
}

/// SSE chunks use `{ "response": "..." }`; REST envelopes use `{ "result": { "response": "..." } }`.
private struct CloudflareStreamEvent: Decodable {
    let success: Bool?
    let errors: [CloudflareAPIError]?
    let response: String?
    let result: CloudflareResult?

    var textDelta: String? {
        if let response, !response.isEmpty { return response }
        return result?.response
    }
}
