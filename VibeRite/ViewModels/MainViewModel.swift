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
    @Published private(set) var isOllamaAvailable = false
    @Published var selectedModel: OllamaModel
    @Published var defaultHotkeyAction: WritingAction

    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings = .shared, permissions: PermissionsManager = .shared) {
        selectedModel = settings.selectedModel
        defaultHotkeyAction = settings.defaultHotkeyAction
        isAccessibilityGranted = permissions.isAccessibilityGranted

        ProcessingStateHolder.shared.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$processingState)

        permissions.$isAccessibilityGranted
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAccessibilityGranted)

        $selectedModel
            .dropFirst()
            .sink { settings.selectedModel = $0 }
            .store(in: &cancellables)

        settings.$defaultHotkeyAction
            .receive(on: DispatchQueue.main)
            .assign(to: &$defaultHotkeyAction)
    }

    func refreshOllamaStatus() {
        Task {
            let available = await OllamaService.shared.isAvailable()
            isOllamaAvailable = available
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
