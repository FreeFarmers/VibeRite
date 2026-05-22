//
//  OllamaSetupState.swift
//  VibeRite
//

import Foundation

enum OllamaSetupState: Equatable {
    case checking
    case notRunning
    case modelNotInstalled
    case downloading(progress: Double?)
    case ready
    case downloadFailed(String)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var statusTitle: String {
        switch self {
        case .checking: return "Checking…"
        case .notRunning: return "Ollama not running"
        case .modelNotInstalled: return "Model not installed"
        case .downloading: return "Downloading model…"
        case .ready: return "Ready"
        case .downloadFailed: return "Download failed"
        }
    }

    var statusDetail: String? {
        switch self {
        case .notRunning:
            return "Start the Ollama app or run `ollama serve` in Terminal."
        case .modelNotInstalled:
            return "Download the selected model to use local writing."
        case .downloading(let progress):
            if let progress {
                return "Progress: \(Int(progress * 100))%"
            }
            return "This may take a few minutes depending on your connection."
        case .downloadFailed(let message):
            return message
        default:
            return nil
        }
    }
}
