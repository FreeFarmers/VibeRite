//
//  WritingAction.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Foundation

/// Supported writing transformations exposed via hotkey, Services menu, and UI.
enum WritingAction: String, CaseIterable, Identifiable, Codable {
    case fixGrammar
    case improveWriting
    case professionalTone
    case friendlyTone
    case makeShorter
    case rewriteClearly
    case summarize

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fixGrammar: return "Fix Grammar"
        case .improveWriting: return "Improve Writing"
        case .professionalTone: return "Professional Tone"
        case .friendlyTone: return "Friendly Tone"
        case .makeShorter: return "Make Shorter"
        case .rewriteClearly: return "Rewrite Clearly"
        case .summarize: return "Summarize"
        }
    }

    /// NSServices message selector suffix (see ServicesProvider).
    var serviceMessage: String {
        switch self {
        case .fixGrammar: return "fixGrammar"
        case .improveWriting: return "improveWriting"
        case .professionalTone: return "professionalTone"
        case .friendlyTone: return "friendlyTone"
        case .makeShorter: return "makeShorter"
        case .rewriteClearly: return "rewriteClearly"
        case .summarize: return "summarize"
        }
    }

    /// Services submenu path shown in the system Services menu.
    var servicesMenuPath: String {
        "VibeRite/\(displayName)"
    }

    /// Default action for the global ⌘⇧F shortcut.
    static let defaultHotkeyAction: WritingAction = .improveWriting
}
