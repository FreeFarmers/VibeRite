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

    private var defaultAction: WritingAction {
        AppSettings.shared.defaultHotkeyAction
    }

    var body: some View {
        Group {
            Section("⌘⇧F Default Action") {
                ForEach(WritingAction.allCases) { action in
                    Button {
                        AppSettings.shared.defaultHotkeyAction = action
                    } label: {
                        HStack {
                            Text(action.displayName)
                            if defaultAction == action {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section {
                Button("\(defaultAction.displayName)  (⌘⇧F)") {
                    WritingCoordinator.shared.processHotkey(action: defaultAction)
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
}
