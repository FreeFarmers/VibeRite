//
//  MainWindowView.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import SwiftUI

struct MainWindowView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                PermissionsView(
                    isGranted: viewModel.isAccessibilityGranted,
                    onRequest: viewModel.requestAccessibility,
                    onOpenSettings: viewModel.openAccessibilitySettings
                )
                ollamaSection
                shortcutsSection
                actionsSection
                servicesSection
            }
            .padding(24)
        }
        .frame(minWidth: 520, minHeight: 640)
        .background(backgroundGradient)
        .onAppear {
            viewModel.refreshOllamaStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("VibeRite")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Private, on-device writing assistant")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Select text in any app, press ⌘⇧F, or use the Services menu to improve writing with local Ollama models.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ollamaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ollama")
                .font(.headline)

            HStack {
                Label(
                    viewModel.isOllamaAvailable ? "Connected" : "Not running",
                    systemImage: viewModel.isOllamaAvailable ? "bolt.fill" : "bolt.slash.fill"
                )
                .foregroundStyle(viewModel.isOllamaAvailable ? .green : .orange)

                Spacer()

                Button("Check") {
                    viewModel.refreshOllamaStatus()
                }
                .buttonStyle(.bordered)
            }

            Picker("Model", selection: $viewModel.selectedModel) {
                ForEach(OllamaModel.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Global Shortcut")
                .font(.headline)
            HStack {
                Text(viewModel.defaultHotkeyAction.displayName)
                Spacer()
                Text("⌘⇧F")
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
            }
            Button("Test \(viewModel.defaultHotkeyAction.displayName)") {
                viewModel.runDefaultHotkeyAction()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isAccessibilityGranted)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Writing Actions")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                ForEach(WritingAction.allCases) { action in
                    Button(action.displayName) {
                        viewModel.runAction(action)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.isAccessibilityGranted || !viewModel.isOllamaAvailable)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)

            Text("Select text, right-click, then choose:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Services")
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("VibeRite")
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Fix Grammar")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                ForEach(WritingAction.allCases) { action in
                    Label(action.displayName, systemImage: "sparkles")
                        .font(.caption)
                        .padding(.leading, 8)
                }
            }

            Text("Enable VibeRite once in System Settings. All writing actions appear under the VibeRite submenu inside Services.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Enable VibeRite in Services") {
                viewModel.openServicesSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(nsColor: .windowBackgroundColor), Color.accentColor.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    MainWindowView()
}
