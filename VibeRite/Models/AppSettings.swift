//
//  AppSettings.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Combine
import Foundation

/// User preferences persisted for future settings UI expansion.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let selectedModel = "viberite.selectedModel"
        static let defaultHotkeyAction = "viberite.defaultHotkeyAction"
        static let hasCompletedOnboarding = "viberite.hasCompletedOnboarding"
    }

    @Published var selectedModel: OllamaModel {
        didSet { UserDefaults.standard.set(selectedModel.rawValue, forKey: Keys.selectedModel) }
    }

    @Published var defaultHotkeyAction: WritingAction {
        didSet { UserDefaults.standard.set(defaultHotkeyAction.rawValue, forKey: Keys.defaultHotkeyAction) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    private init() {
        var storedModel = UserDefaults.standard.string(forKey: Keys.selectedModel)
            ?? UserDefaults.standard.string(forKey: "ritevibe.selectedModel")
        // Migrate old default that doesn't match a typical local install.
        if storedModel == "llama3" {
            storedModel = OllamaModel.default.rawValue
        }
        selectedModel = OllamaModel(rawValue: storedModel ?? "") ?? .default

        let storedAction = UserDefaults.standard.string(forKey: Keys.defaultHotkeyAction)
        defaultHotkeyAction = WritingAction(rawValue: storedAction ?? "") ?? .defaultHotkeyAction

        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
            || UserDefaults.standard.bool(forKey: "ritevibe.hasCompletedOnboarding")
    }
}
