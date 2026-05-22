//
//  AppSettings.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Combine
import Foundation

struct CloudflareCredentials {
    var accountID: String
    var apiToken: String
}

/// User preferences persisted for future settings UI expansion.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let selectedProvider = "viberite.selectedProvider"
        static let selectedModel = "viberite.selectedModel"
        static let selectedCloudflareModel = "viberite.selectedCloudflareModel"
        static let cloudflareAccountID = "viberite.cloudflareAccountID"
        static let defaultHotkeyAction = "viberite.defaultHotkeyAction"
        static let hasCompletedOnboarding = "viberite.hasCompletedOnboarding"
    }

    @Published var selectedProvider: AIModelProvider {
        didSet { UserDefaults.standard.set(selectedProvider.rawValue, forKey: Keys.selectedProvider) }
    }

    @Published var selectedModel: OllamaModel {
        didSet { UserDefaults.standard.set(selectedModel.rawValue, forKey: Keys.selectedModel) }
    }

    @Published var selectedCloudflareModel: CloudflareModel {
        didSet { UserDefaults.standard.set(selectedCloudflareModel.rawValue, forKey: Keys.selectedCloudflareModel) }
    }

    @Published var cloudflareAccountID: String {
        didSet { UserDefaults.standard.set(cloudflareAccountID, forKey: Keys.cloudflareAccountID) }
    }

    @Published var defaultHotkeyAction: WritingAction {
        didSet { UserDefaults.standard.set(defaultHotkeyAction.rawValue, forKey: Keys.defaultHotkeyAction) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    var cloudflareCredentials: CloudflareCredentials {
        CloudflareCredentials(
            accountID: cloudflareAccountID,
            apiToken: KeychainStore.load(KeychainStore.cloudflareTokenKey) ?? ""
        )
    }

    func saveCloudflareToken(_ token: String) {
        if token.isEmpty {
            KeychainStore.delete(KeychainStore.cloudflareTokenKey)
        } else {
            KeychainStore.save(token, for: KeychainStore.cloudflareTokenKey)
        }
        objectWillChange.send()
    }

    var cloudflareTokenConfigured: Bool {
        !(KeychainStore.load(KeychainStore.cloudflareTokenKey) ?? "").isEmpty
    }

    private init() {
        let storedProvider = UserDefaults.standard.string(forKey: Keys.selectedProvider)
        selectedProvider = AIModelProvider(rawValue: storedProvider ?? "") ?? .ollama

        var storedModel = UserDefaults.standard.string(forKey: Keys.selectedModel)
            ?? UserDefaults.standard.string(forKey: "ritevibe.selectedModel")
        if storedModel == "llama3" {
            storedModel = OllamaModel.default.rawValue
        }
        selectedModel = OllamaModel(rawValue: storedModel ?? "") ?? .default

        let storedCloudflareModel = UserDefaults.standard.string(forKey: Keys.selectedCloudflareModel)
        selectedCloudflareModel = CloudflareModel(rawValue: storedCloudflareModel ?? "") ?? .default

        cloudflareAccountID = UserDefaults.standard.string(forKey: Keys.cloudflareAccountID) ?? ""

        let storedAction = UserDefaults.standard.string(forKey: Keys.defaultHotkeyAction)
        defaultHotkeyAction = WritingAction(rawValue: storedAction ?? "") ?? .defaultHotkeyAction

        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
            || UserDefaults.standard.bool(forKey: "ritevibe.hasCompletedOnboarding")
    }
}
