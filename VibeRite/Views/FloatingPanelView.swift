//
//  FloatingPanelView.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import SwiftUI

struct FloatingPanelView: View {
    let state: ProcessingState

    var body: some View {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minWidth: 260)
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
