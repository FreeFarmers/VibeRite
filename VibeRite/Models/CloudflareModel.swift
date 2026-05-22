//
//  CloudflareModel.swift
//  VibeRite
//

import Foundation

/// Cloudflare Workers AI model identifiers.
enum CloudflareModel: String, CaseIterable, Identifiable, Codable {
    case llama38b = "@cf/meta/llama-3-8b-instruct"
    case llama318b = "@cf/meta/llama-3.1-8b-instruct-fp8"
    case llama321b = "@cf/meta/llama-3.2-1b-instruct"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .llama38b: return "Llama 3 8B Instruct"
        case .llama318b: return "Llama 3.1 8B Instruct"
        case .llama321b: return "Llama 3.2 1B Instruct"
        }
    }

    static let `default`: CloudflareModel = .llama38b
}
