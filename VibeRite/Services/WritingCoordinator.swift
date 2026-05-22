//
//  WritingCoordinator.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Combine
import Foundation

/// Orchestrates capture → model → preview → replace for hotkey and Services workflows.
@MainActor
final class WritingCoordinator {
    static let shared = WritingCoordinator()

    private let promptService = PromptTemplateService()
    private let textReplacement = TextReplacementService.shared
    private let llm = LLMService.shared

    let processingState = ProcessingStateHolder.shared
    let floatingPanel = FloatingPanelController.shared

    private struct PendingReplacement {
        let source: Source
        let targetApp: NSRunningApplication?
        let servicePasteboard: NSPasteboard?
        let cleanedText: String
    }

    private var pendingReplacement: PendingReplacement?
    private var previewContinuation: CheckedContinuation<PreviewDecision, Never>?

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
        guard !processingState.state.blocksNewRequests else { return }

        if case .hotkey = source {
            guard PermissionsManager.shared.isReadyForSystemWideUse else {
                processingState.update(.failed("Accessibility permission required."))
                floatingPanel.show(state: processingState.state, nearMouse: true)
                PermissionsManager.shared.requestAccessibility()
                return
            }
        }

        processingState.begin(action: action)

        let targetApp: NSRunningApplication? = {
            if case .hotkey = source { return TextReplacementService.frontmostTargetApp() }
            return nil
        }()

        do {
            processingState.update(.capturingSelection)

            let inputText: String
            switch source {
            case .hotkey:
                inputText = try await textReplacement.captureSelectedText(targetApp: targetApp)
                floatingPanel.show(state: processingState.state, nearMouse: true)
            case .service(let pasteboard):
                inputText = try textReplacement.textFromServicePasteboard(pasteboard)
                floatingPanel.show(state: processingState.state, nearMouse: false)
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

            let servicePasteboard: NSPasteboard? = {
                if case .service(let pasteboard) = source { return pasteboard }
                return nil
            }()

            pendingReplacement = PendingReplacement(
                source: source,
                targetApp: targetApp,
                servicePasteboard: servicePasteboard,
                cleanedText: cleaned
            )

            let decision = await waitForPreviewConfirmation(original: inputText, improved: cleaned)
            pendingReplacement = nil

            guard decision == .apply else {
                processingState.reset()
                floatingPanel.hide()
                return
            }

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
            pendingReplacement = nil
            cancelPreviewContinuation(with: .cancel)
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            processingState.update(.failed(message))
            floatingPanel.refresh(state: processingState.state)
            floatingPanel.scheduleAutoHide(delay: 3.0)
            throw error
        }
    }

    func applyPreview() {
        resumePreview(with: .apply)
    }

    func cancelPreview() {
        resumePreview(with: .cancel)
    }

    private func waitForPreviewConfirmation(original: String, improved: String) async -> PreviewDecision {
        await withCheckedContinuation { continuation in
            previewContinuation = continuation
            processingState.showPreview(original: original, improved: improved)
            floatingPanel.refresh(state: processingState.state)
        }
    }

    private func resumePreview(with decision: PreviewDecision) {
        guard let continuation = previewContinuation else { return }
        previewContinuation = nil
        continuation.resume(returning: decision)
    }

    private func cancelPreviewContinuation(with decision: PreviewDecision) {
        guard let continuation = previewContinuation else { return }
        previewContinuation = nil
        continuation.resume(returning: decision)
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
        var next = state
        next.phase = phase
        state = next
    }

    func setPartial(_ text: String) {
        guard state.phase != .preview, state.phase != .replacingText else { return }

        var next = state
        next.partialResponse = text
        next.phase = .streaming
        state = next
    }

    func showPreview(original: String, improved: String) {
        var next = state
        next.originalText = original
        next.previewText = improved
        next.partialResponse = improved
        next.phase = .preview
        state = next
    }

    func reset() {
        state = ProcessingState()
    }
}
