//
//  FloatingPanelView.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import SwiftUI

struct FloatingPanelView: View {
    @ObservedObject var processingState: ProcessingStateHolder

    private var state: ProcessingState { processingState.state }

    var body: some View {
        Group {
            if case .preview = state.phase {
                previewContent
            } else {
                statusContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 388, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusContent: some View {
        HStack(spacing: 12) {
            statusIcon
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(state.statusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if state.isBusy {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.85)
            }
        }
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }

            previewSection(label: "Original", text: state.originalText, faded: true)
            previewSection(label: "Preview", text: displayPreviewText, faded: false)

            HStack(spacing: 8) {
                Button("Cancel") {
                    WritingCoordinator.shared.cancelPreview()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Apply") {
                    WritingCoordinator.shared.applyPreview()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var displayPreviewText: String {
        if !state.previewText.isEmpty { return state.previewText }
        return state.partialResponse
    }

    private func previewSection(label: String, text: String, faded: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ScrollView {
                Text(text.isEmpty ? "—" : text)
                    .font(.system(size: 11))
                    .foregroundStyle(text.isEmpty ? Color.secondary : (faded ? Color.secondary : Color.primary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 72, maxHeight: 88)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private var title: String {
        if let action = state.action {
            return action.displayName
        }
        return AppConstants.appName
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state.phase {
        case .succeeded:
            Image(systemName: "checkmark.circle.fill")
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
        default:
            Image(systemName: "sparkles")
        }
    }

    private var iconColor: Color {
        switch state.phase {
        case .succeeded:
            return .green
        case .failed:
            return .orange
        default:
            return .accentColor
        }
    }
}
