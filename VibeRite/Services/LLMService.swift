//
//  LLMService.swift
//  VibeRite
//

import Foundation

private struct LLMRequestConfiguration: Sendable {
    let provider: AIModelProvider
    let ollamaModel: OllamaModel
    let cloudflareModel: CloudflareModel
    let cloudflareAccountID: String
    let cloudflareAPIToken: String
}

/// Routes writing requests to the configured local or cloud model provider.
actor LLMService {
    static let shared = LLMService()

    private let ollama = OllamaService.shared
    private let cloudflare = CloudflareService.shared

    private init() {}

    func isAvailable(for provider: AIModelProvider) async -> Bool {
        let configuration = await currentConfiguration()

        switch provider {
        case .ollama:
            return await ollama.isModelReady(configuration.ollamaModel)
        case .cloudflare:
            guard await cloudflare.isConfigured(
                accountID: configuration.cloudflareAccountID,
                apiToken: configuration.cloudflareAPIToken
            ) else {
                return false
            }

            do {
                _ = try await cloudflare.generate(
                    prompt: "Reply with OK.",
                    system: "Reply with the single word OK.",
                    model: configuration.cloudflareModel,
                    accountID: configuration.cloudflareAccountID,
                    apiToken: configuration.cloudflareAPIToken,
                    stream: false,
                    onPartial: nil
                )
                return true
            } catch {
                return false
            }
        }
    }

    func generate(
        prompt: String,
        system: String? = nil,
        onPartial: (@Sendable (String) -> Void)? = nil
    ) async throws -> String {
        let configuration = await currentConfiguration()

        switch configuration.provider {
        case .ollama:
            return try await ollama.generate(
                prompt: prompt,
                system: system,
                model: configuration.ollamaModel,
                onPartial: onPartial
            )
        case .cloudflare:
            guard await cloudflare.isConfigured(
                accountID: configuration.cloudflareAccountID,
                apiToken: configuration.cloudflareAPIToken
            ) else {
                throw CloudflareServiceError.notConfigured
            }

            return try await cloudflare.generate(
                prompt: prompt,
                system: system,
                model: configuration.cloudflareModel,
                accountID: configuration.cloudflareAccountID,
                apiToken: configuration.cloudflareAPIToken,
                onPartial: onPartial
            )
        }
    }

    private func currentConfiguration() async -> LLMRequestConfiguration {
        await MainActor.run {
            let settings = AppSettings.shared
            return LLMRequestConfiguration(
                provider: settings.selectedProvider,
                ollamaModel: settings.selectedModel,
                cloudflareModel: settings.selectedCloudflareModel,
                cloudflareAccountID: settings.cloudflareAccountID,
                cloudflareAPIToken: settings.cloudflareCredentials.apiToken
            )
        }
    }
}
