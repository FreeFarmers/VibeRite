//
//  AccessibilityManager.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import ApplicationServices
import Foundation

/// Wraps Accessibility permission checks and synthetic key events.
final class AccessibilityManager {
    static let shared = AccessibilityManager()

    private init() {}

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user once; returns whether the app is trusted afterward.
    @discardableResult
    func requestAccess(prompt: Bool = true) -> Bool {
        if isTrusted { return true }

        guard prompt else { return false }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Simulates ⌘C or ⌘V using CGEvent — requires Accessibility trust.
    func postCommandKey(keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .combinedSessionState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    /// Brings the app that had focus when the user triggered the hotkey back to the front.
    func activateTargetApp(_ app: NSRunningApplication?) {
        guard let app else { return }
        guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        app.activate(options: [.activateIgnoringOtherApps])
    }

    func copySelection() {
        postCommandKey(keyCode: 8) // kVK_ANSI_C
    }

    func pasteSelection() {
        postCommandKey(keyCode: 9) // kVK_ANSI_V
    }
}
