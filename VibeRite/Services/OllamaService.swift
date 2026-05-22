//
//  OllamaService.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Foundation

enum OllamaServiceError: LocalizedError {
    case notRunning
    case invalidResponse
    case modelError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notRunning:
            return "Ollama is not running. Start it with `ollama serve` and try again."
        case .invalidResponse:
            return "Received an unexpected response from Ollama."
        case .modelError(let message):
            return message
        case .networkError(let message):
            return "Could not reach Ollama: \(message)"
        }
    }
}

/// Talks to the local Ollama HTTP API (fully on-device).
actor OllamaService {
    static let shared = OllamaService()

    private let session: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
    }

    func isAvailable() async -> Bool {
        var request = URLRequest(url: AppConstants.ollamaTagsURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 3

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        } catch {
            return false
        }
    }

    /// Streams tokens from `/api/generate` and returns the assembled result.
    func generate(
        prompt: String,
        system: String? = nil,
        model: OllamaModel,
        onPartial: (@Sendable (String) -> Void)? = nil
    ) async throws -> String {
        guard await isAvailable() else {
            throw OllamaServiceError.notRunning
        }

        var request = URLRequest(url: AppConstants.ollamaGenerateURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OllamaGenerateRequest(
            model: model.rawValue,
            prompt: prompt,
            system: system,
            stream: true,
            options: OllamaGenerateOptions(temperature: 0.2, topP: 0.9)
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await session.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OllamaServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 404 {
                throw OllamaServiceError.modelError(
                    "Model \"\(model.rawValue)\" is not installed. Run `ollama pull \(model.rawValue)`."
                )
            }
            throw OllamaServiceError.networkError("HTTP \(http.statusCode)")
        }

        var fullText = ""

        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8), !line.isEmpty else { continue }
            let chunk = try decoder.decode(OllamaStreamChunk.self, from: data)

            if let error = chunk.error, !error.isEmpty {
                throw OllamaServiceError.modelError(error)
            }

            if let piece = chunk.response {
                fullText += piece
                onPartial?(fullText)
            }

            if chunk.done == true { break }
        }

        let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OllamaServiceError.invalidResponse
        }

        return trimmed
    }
}

private struct OllamaGenerateRequest: Encodable {
    let model: String
    let prompt: String
    let system: String?
    let stream: Bool
    let options: OllamaGenerateOptions?
}

private struct OllamaGenerateOptions: Encodable {
    let temperature: Double
    let topP: Double

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
    }
}

private struct OllamaStreamChunk: Decodable {
    let response: String?
    let done: Bool?
    let error: String?
}
