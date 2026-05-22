//
//  PermissionsView.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import SwiftUI

struct PermissionsView: View {
    let isGranted: Bool
    let onRequest: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Accessibility", systemImage: "hand.raised.fill")
                .font(.headline)

            Text("VibeRite reads your selection and pastes improved text using secure clipboard workflows. Accessibility permission is required for ⌘⇧F and automatic replacement.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                statusBadge

                if !isGranted {
                    Button("Request Access", action: onRequest)
                        .buttonStyle(.borderedProminent)
                    Button("Open Settings", action: onOpenSettings)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusBadge: some View {
        Label(
            isGranted ? "Enabled" : "Required",
            systemImage: isGranted ? "checkmark.seal.fill" : "exclamationmark.circle.fill"
        )
        .font(.subheadline.weight(.medium))
        .foregroundStyle(isGranted ? .green : .orange)
    }
}
