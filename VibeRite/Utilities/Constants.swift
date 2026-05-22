//
//  Constants.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Carbon.HIToolbox
import Foundation

enum AppConstants {
    static let appName = "VibeRite"
    static let bundleIdentifier = "com.BitsVessel.VibeRite"

    static let ollamaGenerateURL = URL(string: "http://localhost:11434/api/generate")!
    static let ollamaTagsURL = URL(string: "http://localhost:11434/api/tags")!
    static let ollamaPullURL = URL(string: "http://localhost:11434/api/pull")!

    /// Global shortcut: ⌘⇧F
    static let hotkeyKeyCode: UInt32 = 3 // kVK_ANSI_F
    static let hotkeyModifiers: UInt32 = UInt32(cmdKey | shiftKey)

    static let maxInputCharacters = 12_000
    /// Time for the target app to respond to synthetic ⌘C / ⌘V.
    static let targetAppActivateDelay: TimeInterval = 0.08
    static let clipboardCaptureDelay: TimeInterval = 0.22
    static let pasteDelay: TimeInterval = 0.45
}
