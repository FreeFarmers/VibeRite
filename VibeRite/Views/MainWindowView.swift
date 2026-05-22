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
            viewModel.refreshModelStatus()
        }
        .onChange(of: viewModel.selectedProvider) { _, _ in
            viewModel.refreshModelStatus()
        }
        .onChange(of: viewModel.cloudflareAccountID) { _, _ in
            viewModel.refreshModelStatus()
        }
        .onChange(of: viewModel.cloudflareAPIToken) { _, _ in
            viewModel.refreshModelStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(4)
                    .background(.black, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("VibeRite")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Local & cloud writing assistant")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Select text in any app, press ⌘⇧F, or use the Services menu to improve writing with local Ollama or Cloudflare AI.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ollamaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Model")
                .font(.headline)

            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(AIModelProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.segmented)

            Text(viewModel.selectedProvider.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label(
                    viewModel.isModelAvailable ? "Ready" : statusLabel,
                    systemImage: viewModel.isModelAvailable ? "bolt.fill" : "bolt.slash.fill"
                )
                .foregroundStyle(viewModel.isModelAvailable ? .green : .orange)

                Spacer()

                Button("Check") {
                    viewModel.refreshModelStatus()
                }
                .buttonStyle(.bordered)
            }

            switch viewModel.selectedProvider {
            case .ollama:
                Picker("Model", selection: $viewModel.selectedModel) {
                    ForEach(OllamaModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.segmented)

            case .cloudflare:
                VStack(alignment: .leading, spacing: 10) {
                    Text("Selected text is sent to Cloudflare for processing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Account ID", text: $viewModel.cloudflareAccountID)
                        .textFieldStyle(.roundedBorder)

                    SecureField("API Token", text: $viewModel.cloudflareAPIToken)
                        .textFieldStyle(.roundedBorder)

                    Picker("Model", selection: $viewModel.selectedCloudflareModel) {
                        ForEach(CloudflareModel.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusLabel: String {
        switch viewModel.selectedProvider {
        case .ollama:
            return "Not running"
        case .cloudflare:
            return "Not configured"
        }
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
                    .disabled(!viewModel.isAccessibilityGranted || !viewModel.isModelAvailable)
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
