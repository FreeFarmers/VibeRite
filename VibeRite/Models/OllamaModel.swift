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
}
