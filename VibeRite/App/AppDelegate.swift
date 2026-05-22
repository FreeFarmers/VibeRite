//
//  AppDelegate.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit

/// AppKit bridge for Services registration, hotkeys, and background readiness.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Register before launch completes so macOS picks up NSServices for the context menu.
        ContextMenuManager.shared.registerServices()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        Task { @MainActor in
            ContextMenuManager.shared.registerServices()
            PermissionsManager.shared.refresh()

            HotkeyManager.shared.register {
                Task { @MainActor in
                    let action = AppSettings.shared.defaultHotkeyAction
                    WritingCoordinator.shared.processHotkey(action: action)
                }
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        ContextMenuManager.shared.registerServices()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }
}
