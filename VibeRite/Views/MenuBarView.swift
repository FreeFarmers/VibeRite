//
//  MenuBarView.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Group {
            Section("Writing Actions") {
                ForEach(WritingAction.allCases) { action in
                    Button {
                        WritingCoordinator.shared.processHotkey(action: action)
                    } label: {
                        Label(action.displayName, systemImage: icon(for: action))
                    }
                }
            }

            Section("⌘⇧F Default Action") {
                ForEach(WritingAction.allCases) { action in
                    Button {
                        settings.defaultHotkeyAction = action
                    } label: {
                        HStack {
                            Text(action.displayName)
                            if settings.defaultHotkeyAction == action {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section {
                Button("\(settings.defaultHotkeyAction.displayName)  (⌘⇧F)") {
                    WritingCoordinator.shared.processHotkey(action: settings.defaultHotkeyAction)
                }

                Button("Open VibeRite") {
                    openMainWindow()
                }

                Button("Quit VibeRite") {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    private func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
    }

    private func icon(for action: WritingAction) -> String {
        switch action {
        case .fixGrammar: return "textformat.abc"
        case .improveWriting: return "sparkles"
        case .professionalTone: return "briefcase"
        case .friendlyTone: return "face.smiling"
        case .makeShorter: return "arrow.down.right.and.arrow.up.left"
        case .rewriteClearly: return "text.alignleft"
        case .summarize: return "text.justify.leading"
        }
    }
}
