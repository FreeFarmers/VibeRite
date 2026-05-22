//
//  TextReplacementService.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Foundation

enum TextReplacementError: LocalizedError {
    case accessibilityRequired
    case noSelection
    case inputTooLong
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .accessibilityRequired:
            return "Enable Accessibility for VibeRite in System Settings."
        case .noSelection:
            return "No text selected. Select text in any app, then try again."
        case .inputTooLong:
            return "Selection is too long. Try a shorter passage."
        case .emptyResult:
            return "AI returned an empty result."
        }
    }
}

/// Captures selected text via clipboard, transforms it, and pastes the result back.
@MainActor
final class TextReplacementService {
    static let shared = TextReplacementService()

    private let clipboard = ClipboardManager.shared
    private let accessibility = AccessibilityManager.shared

    private init() {}

    /// Remembers which app had focus when the hotkey fired (must be captured before showing VibeRite UI).
    static func frontmostTargetApp() -> NSRunningApplication? {
        NSWorkspace.shared.frontmostApplication
    }

    /// Copies the current selection to the pasteboard and returns its text.
    func captureSelectedText(targetApp: NSRunningApplication?) async throws -> String {
        guard accessibility.isTrusted else {
            throw TextReplacementError.accessibilityRequired
        }

        accessibility.activateTargetApp(targetApp)
        try await Task.sleep(nanoseconds: UInt64(AppConstants.targetAppActivateDelay * 1_000_000_000))

        let snapshot = clipboard.snapshot()
        accessibility.copySelection()

        try await Task.sleep(nanoseconds: UInt64(AppConstants.clipboardCaptureDelay * 1_000_000_000))

        guard let text = clipboard.readString(), !text.isEmpty else {
            clipboard.restore(snapshot)
            throw TextReplacementError.noSelection
        }

        if text.count > AppConstants.maxInputCharacters {
            clipboard.restore(snapshot)
            throw TextReplacementError.inputTooLong
        }

        clipboard.restore(snapshot)
        return text
    }

    /// Writes improved text to the pasteboard and pastes it into the target app.
    func replaceSelection(with text: String, targetApp: NSRunningApplication?) async throws {
        guard accessibility.isTrusted else {
            throw TextReplacementError.accessibilityRequired
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TextReplacementError.emptyResult
        }

        accessibility.activateTargetApp(targetApp)
        try await Task.sleep(nanoseconds: UInt64(AppConstants.targetAppActivateDelay * 1_000_000_000))

        let snapshot = clipboard.snapshot()
        clipboard.writeString(trimmed)
        accessibility.pasteSelection()

        try await Task.sleep(nanoseconds: UInt64(AppConstants.pasteDelay * 1_000_000_000))
        clipboard.restore(snapshot)
    }

    /// Services workflow: pasteboard already contains the selected text.
    func textFromServicePasteboard(_ pasteboard: NSPasteboard) throws -> String {
        guard let text = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw TextReplacementError.noSelection
        }

        if text.count > AppConstants.maxInputCharacters {
            throw TextReplacementError.inputTooLong
        }

        return text
    }

    /// Writes transformed text back into the service pasteboard.
    func writeToServicePasteboard(_ pasteboard: NSPasteboard, text: String) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TextReplacementError.emptyResult
        }
        pasteboard.clearContents()
        pasteboard.setString(trimmed, forType: .string)
    }
}
