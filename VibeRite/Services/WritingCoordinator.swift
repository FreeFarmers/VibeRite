//
//  WritingCoordinator.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Combine
import Foundation

/// Orchestrates capture → Ollama → replace for hotkey and Services workflows.
@MainActor
final class WritingCoordinator {
    static let shared = WritingCoordinator()

    private let promptService = PromptTemplateService()
    private let textReplacement = TextReplacementService.shared
    private let llm = LLMService.shared

    let processingState = ProcessingStateHolder.shared
    let floatingPanel = FloatingPanelController.shared

    private init() {}

    func processHotkey(action: WritingAction = .defaultHotkeyAction) {
        Task {
            try? await process(action: action, source: .hotkey)
        }
    }

    enum Source {
        case hotkey
        case service(NSPasteboard)
    }

    func process(action: WritingAction, source: Source) async throws {
        guard !processingState.state.isBusy else { return }

        if case .hotkey = source {
            guard PermissionsManager.shared.isReadyForSystemWideUse else {
                processingState.update(.failed("Accessibility permission required."))
                floatingPanel.show(state: processingState.state, nearMouse: true)
                PermissionsManager.shared.requestAccessibility()
                return
            }
        }

        processingState.begin(action: action)

        // Remember the app where text is selected before any VibeRite UI appears.
        let targetApp: NSRunningApplication? = {
            if case .hotkey = source { return TextReplacementService.frontmostTargetApp() }
            return nil
        }()

        do {
            processingState.update(.capturingSelection)

            let inputText: String
            switch source {
            case .hotkey:
                // Capture while the target app still has focus (don't activate VibeRite first).
                inputText = try await textReplacement.captureSelectedText(targetApp: targetApp)
                floatingPanel.show(state: processingState.state, nearMouse: true)
            case .service(let pasteboard):
                inputText = try textReplacement.textFromServicePasteboard(pasteboard)
                floatingPanel.show(state: processingState.state, nearMouse: true)
            }

            processingState.update(.contactingModel)
            floatingPanel.refresh(state: processingState.state)

            let prompt = promptService.buildPrompt(action: action, userText: inputText)

            processingState.update(.streaming)
            floatingPanel.refresh(state: processingState.state)

            let improved = try await llm.generate(
                prompt: prompt,
                system: promptService.systemPrompt
            ) { [weak self] partial in
                Task { @MainActor in
                    self?.processingState.setPartial(partial)
                    self?.floatingPanel.refresh(state: self?.processingState.state ?? ProcessingState())
                }
            }

            let cleaned = promptService.sanitizeModelOutput(improved)

            processingState.update(.replacingText)
            floatingPanel.refresh(state: processingState.state)

            switch source {
            case .hotkey:
                try await textReplacement.replaceSelection(with: cleaned, targetApp: targetApp)
            case .service(let pasteboard):
                try textReplacement.writeToServicePasteboard(pasteboard, text: cleaned)
            }

            processingState.update(.succeeded)
            floatingPanel.refresh(state: processingState.state)
            floatingPanel.scheduleAutoHide()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            processingState.update(.failed(message))
            floatingPanel.refresh(state: processingState.state)
            floatingPanel.scheduleAutoHide(delay: 3.0)
            throw error
        }
    }
}

/// Shared observable processing state for UI bindings.
@MainActor
final class ProcessingStateHolder: ObservableObject {
    static let shared = ProcessingStateHolder()

    @Published private(set) var state = ProcessingState()

    private init() {}

    func begin(action: WritingAction) {
        state = ProcessingState(phase: .capturingSelection, action: action, partialResponse: "")
    }

    func update(_ phase: ProcessingPhase) {
        state.phase = phase
    }

    func setPartial(_ text: String) {
        state.partialResponse = text
        state.phase = .streaming
    }
}
