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
    @Published private(set) var ollamaSetupState: OllamaSetupState = .checking
    @Published var selectedProvider: AIModelProvider
    @Published var selectedModel: OllamaModel
    @Published var selectedCloudflareModel: CloudflareModel
    @Published var cloudflareAccountID: String
    @Published var cloudflareAPIToken: String
    @Published var defaultHotkeyAction: WritingAction
    @Published private(set) var didCopyCommand = false

    private var cancellables = Set<AnyCancellable>()
    private var copyResetTask: Task<Void, Never>?
    private var statusRefreshTask: Task<Void, Never>?
    private var statusRefreshGeneration = 0

    init(settings: AppSettings = .shared, permissions: PermissionsManager = .shared) {
        selectedProvider = settings.selectedProvider
        selectedModel = settings.selectedModel
        selectedCloudflareModel = settings.selectedCloudflareModel
        cloudflareAccountID = settings.cloudflareAccountID
        cloudflareAPIToken = settings.cloudflareCredentials.apiToken
        defaultHotkeyAction = settings.defaultHotkeyAction
        isAccessibilityGranted = permissions.isAccessibilityGranted

        ProcessingStateHolder.shared.$state
            .removeDuplicates()
            .sink { [weak self] state in
                self?.deferPublishedUpdate {
                    self?.processingState = state
                }
            }
            .store(in: &cancellables)

        permissions.$isAccessibilityGranted
            .removeDuplicates()
            .sink { [weak self] granted in
                self?.deferPublishedUpdate {
                    self?.isAccessibilityGranted = granted
                }
            }
            .store(in: &cancellables)

        settings.$defaultHotkeyAction
            .removeDuplicates()
            .sink { [weak self] action in
                self?.deferPublishedUpdate {
                    self?.defaultHotkeyAction = action
                }
            }
            .store(in: &cancellables)
    }

    func applyModelSelection(_ model: OllamaModel) {
        selectedModel = model
        ollamaSetupState = .checking
        isModelAvailable = false
        AppSettings.shared.persistSelectedModel(model)
        refreshModelStatus()
    }

    func applyProviderSelection(_ provider: AIModelProvider) {
        selectedProvider = provider
        ollamaSetupState = .checking
        isModelAvailable = false
        AppSettings.shared.persistSelectedProvider(provider)
        refreshModelStatus()
    }

    func applyCloudflareModelSelection(_ model: CloudflareModel) {
        selectedCloudflareModel = model
        ollamaSetupState = .checking
        isModelAvailable = false
        AppSettings.shared.persistSelectedCloudflareModel(model)
        refreshModelStatus()
    }

    func applyCloudflareAccountID(_ accountID: String) {
        cloudflareAccountID = accountID
        AppSettings.shared.persistCloudflareAccountID(accountID)
        refreshModelStatus()
    }

    func applyCloudflareToken(_ token: String) {
        cloudflareAPIToken = token
        AppSettings.shared.saveCloudflareToken(token)
        refreshModelStatus()
    }

    func refreshModelStatus() {
        statusRefreshTask?.cancel()
        statusRefreshGeneration += 1
        let generation = statusRefreshGeneration
        let provider = selectedProvider
        let ollamaModel = selectedModel

        statusRefreshTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, generation == statusRefreshGeneration else { return }

            switch provider {
            case .ollama:
                await refreshOllamaStatus(model: ollamaModel, generation: generation)
            case .cloudflare:
                ollamaSetupState = .checking
                let available = await LLMService.shared.isAvailable(for: .cloudflare)
                guard generation == statusRefreshGeneration, !Task.isCancelled else { return }
                isModelAvailable = available
            }
        }
    }

    func downloadSelectedModel() {
        guard selectedProvider == .ollama else { return }
        if case .downloading = ollamaSetupState { return }
        startModelDownload()
    }

    func copyPullCommand() {
        copyToPasteboard(selectedModel.pullCommand)
    }

    func copyServeCommand() {
        copyToPasteboard("ollama serve")
    }

    func openTerminalWithPullCommand() {
        openTerminal(with: selectedModel.pullCommand)
    }

    func openTerminalWithServeCommand() {
        openTerminal(with: "ollama serve")
    }

    private func refreshOllamaStatus(model: OllamaModel, generation: Int) async {
        guard generation == statusRefreshGeneration, !Task.isCancelled else { return }
        ollamaSetupState = .checking
        isModelAvailable = false

        let running = await OllamaService.shared.isAvailable()
        guard generation == statusRefreshGeneration, !Task.isCancelled else { return }

        guard running else {
            ollamaSetupState = .notRunning
            isModelAvailable = false
            return
        }

        let installed = await OllamaService.shared.isModelInstalled(model)
        guard generation == statusRefreshGeneration, !Task.isCancelled else { return }

        if installed {
            ollamaSetupState = .ready
            isModelAvailable = true
        } else {
            ollamaSetupState = .modelNotInstalled
            isModelAvailable = false
        }
    }

    private func startModelDownload() {
        let model = selectedModel
        let generation = statusRefreshGeneration
        ollamaSetupState = .downloading(progress: nil)
        isModelAvailable = false

        Task {
            do {
                try await OllamaService.shared.pull(model: model) { [weak self] progress in
                    Task { @MainActor in
                        guard let self, generation == self.statusRefreshGeneration else { return }
                        self.ollamaSetupState = .downloading(progress: progress)
                    }
                }
                guard generation == statusRefreshGeneration else { return }
                ollamaSetupState = .ready
                isModelAvailable = true
            } catch {
                guard generation == statusRefreshGeneration else { return }
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                ollamaSetupState = .downloadFailed(message)
                isModelAvailable = false
            }
        }
    }

    private func deferPublishedUpdate(_ update: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            await Task.yield()
            update()
        }
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        didCopyCommand = true
        copyResetTask?.cancel()
        copyResetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            didCopyCommand = false
        }
    }

    private func openTerminal(with command: String) {
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
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
