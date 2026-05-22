//
//  PermissionsManager.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Combine
import Foundation

/// Aggregates permission state for the onboarding UI.
@MainActor
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published private(set) var isAccessibilityGranted = false

    private var pollTimer: Timer?

    private init() {
        refresh()
        startPolling()
    }

    func refresh() {
        isAccessibilityGranted = AccessibilityManager.shared.isTrusted
    }

    func requestAccessibility() {
        _ = AccessibilityManager.shared.requestAccess(prompt: true)
        refresh()
    }

    func openAccessibilitySettings() {
        AccessibilityManager.shared.openAccessibilitySettings()
    }

    var isReadyForSystemWideUse: Bool {
        isAccessibilityGranted
    }

    var statusSummary: String {
        if isAccessibilityGranted {
            return "Accessibility enabled — VibeRite can read and replace selected text."
        }
        return "Accessibility required — enable VibeRite in System Settings → Privacy & Security → Accessibility."
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        pollTimer?.invalidate()
    }
}
