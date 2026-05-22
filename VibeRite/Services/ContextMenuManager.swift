//
//  ContextMenuManager.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Foundation

/// Registers macOS Services entries so VibeRite appears in the system Services submenu.
@MainActor
final class ContextMenuManager: NSObject {
    static let shared = ContextMenuManager()

    private override init() {
        super.init()
    }

    func registerServices() {
        NSApp.servicesProvider = ServicesProvider.shared
        NSUpdateDynamicServices()
    }

    /// Opens System Settings so the user can enable VibeRite under Services.
    func openServicesSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Services",
            "x-apple.systempreferences:com.apple.preference.keyboard?Services",
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}

/// NSObject services provider — selectors must match Info.plist `NSMessage` values.
@objc final class ServicesProvider: NSObject {
    static let shared = ServicesProvider()

    private let coordinator = WritingCoordinator.shared

    @objc func fixGrammar(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.fixGrammar, pasteboard: pasteboard, error: error)
    }

    @objc func improveWriting(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.improveWriting, pasteboard: pasteboard, error: error)
    }

    @objc func professionalTone(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.professionalTone, pasteboard: pasteboard, error: error)
    }

    @objc func friendlyTone(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.friendlyTone, pasteboard: pasteboard, error: error)
    }

    @objc func makeShorter(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.makeShorter, pasteboard: pasteboard, error: error)
    }

    @objc func rewriteClearly(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.rewriteClearly, pasteboard: pasteboard, error: error)
    }

    @objc func summarize(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.summarize, pasteboard: pasteboard, error: error)
    }

    /// Services must finish before returning — spin the run loop while the async pipeline completes.
    private func run(
        _ action: WritingAction,
        pasteboard: NSPasteboard,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let group = DispatchGroup()
        group.enter()

        Task { @MainActor in
            defer { group.leave() }
            do {
                try await coordinator.process(action: action, source: .service(pasteboard))
            } catch let processingError {
                error.pointee = (processingError as NSError).localizedDescription as NSString
            }
        }

        while group.wait(timeout: .now()) != .success {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
    }
}
