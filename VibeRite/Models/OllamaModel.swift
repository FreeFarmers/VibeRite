//
//  OllamaModel.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Foundation

/// Locally supported Ollama model identifiers (must match `ollama list` names exactly).
enum OllamaModel: String, CaseIterable, Identifiable, Codable {
    case llama32_3b = "llama3.2:3b"
    case llama3
    case mistral
    case gemma

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .llama32_3b: return "Llama 3.2 (3B)"
        case .llama3: return "Llama 3"
        case .mistral: return "Mistral"
        case .gemma: return "Gemma"
        }
    }

    static let `default`: OllamaModel = .llama32_3b

    var pullCommand: String {
        "ollama pull \(rawValue)"
    }

    func matchesInstalledName(_ installedName: String) -> Bool {
        if installedName == rawValue { return true }
        if installedName.hasPrefix("\(rawValue):") { return true }

        // Require exact match when the supported model includes a tag (e.g. llama3.2:3b).
        if rawValue.contains(":") {
            return false
        }

        let installedBase = installedName.split(separator: ":", maxSplits: 1).first.map(String.init) ?? installedName
        return installedBase == rawValue
    }
}
