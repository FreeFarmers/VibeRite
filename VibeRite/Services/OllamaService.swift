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
    case pullFailed(String)

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
        case .pullFailed(let message):
            return message
        }
    }
}

/// Talks to the local Ollama HTTP API (fully on-device).
actor OllamaService {
    static let shared = OllamaService()

    private let session: URLSession
    private let pullSession: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)

        let pullConfig = URLSessionConfiguration.ephemeral
        pullConfig.timeoutIntervalForRequest = 300
        pullConfig.timeoutIntervalForResource = 3_600
        pullSession = URLSession(configuration: pullConfig)
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

    func installedModelNames() async throws -> [String] {
        var request = URLRequest(url: AppConstants.ollamaTagsURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw OllamaServiceError.notRunning
        }

        let tags = try decoder.decode(OllamaTagsResponse.self, from: data)
        return tags.models?.map(\.name) ?? []
    }

    func isModelInstalled(_ model: OllamaModel) async -> Bool {
        guard await isAvailable() else { return false }
        guard let names = try? await installedModelNames() else { return false }
        return names.contains { model.matchesInstalledName($0) }
    }

    func isModelReady(_ model: OllamaModel) async -> Bool {
        await isModelInstalled(model)
    }

    func pull(
        model: OllamaModel,
        onProgress: (@Sendable (Double?) -> Void)? = nil
    ) async throws {
        guard await isAvailable() else {
            throw OllamaServiceError.notRunning
        }

        var request = URLRequest(url: AppConstants.ollamaPullURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(OllamaPullRequest(name: model.rawValue, stream: true))

        let (bytes, response) = try await pullSession.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OllamaServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw OllamaServiceError.networkError("HTTP \(http.statusCode)")
        }

        var sawSuccess = false

        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8), !line.isEmpty else { continue }
            let chunk = try decoder.decode(OllamaPullChunk.self, from: data)

            if let error = chunk.error, !error.isEmpty {
                throw OllamaServiceError.pullFailed(error)
            }

            if chunk.status == "success" {
                sawSuccess = true
                onProgress?(1.0)
                break
            }

            if let total = chunk.total, total > 0, let completed = chunk.completed {
                onProgress?(min(1.0, Double(completed) / Double(total)))
            } else {
                onProgress?(nil)
            }
        }

        if sawSuccess { return }
        if await isModelInstalled(model) { return }
        throw OllamaServiceError.pullFailed("Model download did not complete.")
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

        guard await isModelInstalled(model) else {
            throw OllamaServiceError.modelError(
                "Model \"\(model.rawValue)\" is not installed. Run `\(model.pullCommand)`."
            )
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
                    "Model \"\(model.rawValue)\" is not installed. Run `\(model.pullCommand)`."
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

private struct OllamaTagsResponse: Decodable {
    let models: [OllamaTagModel]?
}

private struct OllamaTagModel: Decodable {
    let name: String
}

private struct OllamaPullRequest: Encodable {
    let name: String
    let stream: Bool
}

private struct OllamaPullChunk: Decodable {
    let status: String?
    let completed: Int?
    let total: Int?
    let error: String?
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
