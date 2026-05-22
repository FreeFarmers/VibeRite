//
//  MainViewModel.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Combine
import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    @Published private(set) var processingState: ProcessingState = ProcessingStateHolder.shared.state
    @Published private(set) var isAccessibilityGranted = false
    @Published private(set) var isModelAvailable = false
    @Published var selectedProvider: AIModelProvider
    @Published var selectedModel: OllamaModel
    @Published var selectedCloudflareModel: CloudflareModel
    @Published var cloudflareAccountID: String
    @Published var cloudflareAPIToken: String
    @Published var defaultHotkeyAction: WritingAction

    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings = .shared, permissions: PermissionsManager = .shared) {
        selectedProvider = settings.selectedProvider
        selectedModel = settings.selectedModel
        selectedCloudflareModel = settings.selectedCloudflareModel
        cloudflareAccountID = settings.cloudflareAccountID
        cloudflareAPIToken = settings.cloudflareCredentials.apiToken
        defaultHotkeyAction = settings.defaultHotkeyAction
        isAccessibilityGranted = permissions.isAccessibilityGranted

        ProcessingStateHolder.shared.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$processingState)

        permissions.$isAccessibilityGranted
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAccessibilityGranted)

        $selectedProvider
            .dropFirst()
            .sink { settings.selectedProvider = $0 }
            .store(in: &cancellables)

        $selectedModel
            .dropFirst()
            .sink { settings.selectedModel = $0 }
            .store(in: &cancellables)

        $selectedCloudflareModel
            .dropFirst()
            .sink { settings.selectedCloudflareModel = $0 }
            .store(in: &cancellables)

        $cloudflareAccountID
            .dropFirst()
            .sink { settings.cloudflareAccountID = $0 }
            .store(in: &cancellables)

        $cloudflareAPIToken
            .dropFirst()
            .sink { settings.saveCloudflareToken($0) }
            .store(in: &cancellables)

        settings.$defaultHotkeyAction
            .receive(on: DispatchQueue.main)
            .assign(to: &$defaultHotkeyAction)
    }

    func refreshModelStatus() {
        Task {
            let available = await LLMService.shared.isAvailable(for: selectedProvider)
            isModelAvailable = available
        }
    }

    func requestAccessibility() {
        PermissionsManager.shared.requestAccessibility()
    }

    func openAccessibilitySettings() {
        PermissionsManager.shared.openAccessibilitySettings()
    }

    func runAction(_ action: WritingAction) {
        WritingCoordinator.shared.processHotkey(action: action)
    }

    func runDefaultHotkeyAction() {
        runAction(defaultHotkeyAction)
    }

    func openServicesSettings() {
        ContextMenuManager.shared.openServicesSettings()
    }
}
