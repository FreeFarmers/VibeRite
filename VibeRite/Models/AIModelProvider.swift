//
//  AIModelProvider.swift
//  VibeRite
//

import Foundation

/// Where VibeRite sends writing requests.
enum AIModelProvider: String, CaseIterable, Identifiable, Codable {
    case ollama
    case cloudflare

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama: return "Local (Ollama)"
        case .cloudflare: return "Cloudflare AI"
        }
    }

    var subtitle: String {
        switch self {
        case .ollama: return "Private, on-device"
        case .cloudflare: return "Cloud-hosted Llama models"
        }
    }
}
