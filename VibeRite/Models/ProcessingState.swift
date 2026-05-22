//
//  ProcessingState.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Foundation

enum ProcessingPhase: Equatable {
    case idle
    case capturingSelection
    case contactingModel
    case streaming
    case preview
    case replacingText
    case succeeded
    case failed(String)
}

struct ProcessingState: Equatable {
    var phase: ProcessingPhase = .idle
    var action: WritingAction?
    var partialResponse: String = ""
    var originalText: String = ""
    var previewText: String = ""

    var isBusy: Bool {
        switch phase {
        case .idle, .succeeded, .failed, .preview:
            return false
        default:
            return true
        }
    }

    var blocksNewRequests: Bool {
        switch phase {
        case .idle, .succeeded, .failed:
            return false
        default:
            return true
        }
    }

    var statusMessage: String {
        switch phase {
        case .idle:
            return "Ready"
        case .capturingSelection:
            return "Reading selection…"
        case .contactingModel:
            return "Connecting to model…"
        case .streaming:
            return "Improving text…"
        case .preview:
            return "Review the preview, then apply or cancel."
        case .replacingText:
            return "Applying changes…"
        case .succeeded:
            return "Done"
        case .failed(let message):
            return message
        }
    }
}

enum PreviewDecision: Equatable {
    case apply
    case cancel
}
