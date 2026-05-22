//
//  MainWindowView.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import SwiftUI

struct MainWindowView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var pickerProvider: AIModelProvider = AppSettings.shared.selectedProvider
    @State private var pickerModel: OllamaModel = AppSettings.shared.selectedModel
    @State private var pickerCloudflareModel: CloudflareModel = AppSettings.shared.selectedCloudflareModel

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
            pickerProvider = viewModel.selectedProvider
            pickerModel = viewModel.selectedModel
            pickerCloudflareModel = viewModel.selectedCloudflareModel
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

            Picker("Provider", selection: $pickerProvider) {
                ForEach(AIModelProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: pickerProvider) { _, newValue in
                viewModel.applyProviderSelection(newValue)
            }

            Text(pickerProvider.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            statusRow

            switch pickerProvider {
            case .ollama:
                Picker("Model", selection: $pickerModel) {
                    ForEach(OllamaModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: pickerModel) { _, newValue in
                    viewModel.applyModelSelection(newValue)
                }

                ollamaSetupSection

            case .cloudflare:
                VStack(alignment: .leading, spacing: 10) {
                    Text("Selected text is sent to Cloudflare for processing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Account ID", text: $viewModel.cloudflareAccountID)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            viewModel.applyCloudflareAccountID(viewModel.cloudflareAccountID)
                        }

                    SecureField("API Token", text: $viewModel.cloudflareAPIToken)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            viewModel.applyCloudflareToken(viewModel.cloudflareAPIToken)
                        }

                    Picker("Model", selection: $pickerCloudflareModel) {
                        ForEach(CloudflareModel.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: pickerCloudflareModel) { _, newValue in
                        viewModel.applyCloudflareModelSelection(newValue)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusRow: some View {
        HStack {
            Label(
                statusTitle,
                systemImage: statusIcon
            )
            .foregroundStyle(statusColor)

            Spacer()

            Button("Check") {
                viewModel.refreshModelStatus()
            }
            .buttonStyle(.bordered)
        }
    }

    private var ollamaSetupSection: some View {
        Group {
            if pickerProvider == .ollama {
                switch viewModel.ollamaSetupState {
                case .checking:
                    EmptyView()

                case .ready:
                    EmptyView()

                case .notRunning:
                    ollamaHelpBox(
                        detail: "Start Ollama, then check again.",
                        command: "ollama serve",
                        primaryTitle: "Copy `ollama serve`",
                        primaryAction: viewModel.copyServeCommand,
                        secondaryTitle: "Open in Terminal",
                        secondaryAction: viewModel.openTerminalWithServeCommand
                    )

                case .modelNotInstalled:
                    ollamaHelpBox(
                        detail: "\(viewModel.selectedModel.displayName) is not installed yet.",
                        command: viewModel.selectedModel.pullCommand,
                        primaryTitle: "Download model",
                        primaryAction: viewModel.downloadSelectedModel,
                        secondaryTitle: viewModel.didCopyCommand ? "Copied!" : "Copy pull command",
                        secondaryAction: viewModel.copyPullCommand
                    )

                case .downloading(let progress):
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Downloading \(viewModel.selectedModel.displayName)…")
                            .font(.subheadline)
                        if let progress {
                            ProgressView(value: progress)
                        } else {
                            ProgressView()
                        }
                        Text("Keep Ollama running until the download finishes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                case .downloadFailed(let message):
                    ollamaHelpBox(
                        detail: message,
                        command: viewModel.selectedModel.pullCommand,
                        primaryTitle: "Try again",
                        primaryAction: viewModel.downloadSelectedModel,
                        secondaryTitle: "Copy pull command",
                        secondaryAction: viewModel.copyPullCommand
                    )
                }
            }
        }
    }

    private func ollamaHelpBox(
        detail: String,
        command: String,
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(.borderedProminent)
                Button(secondaryTitle, action: secondaryAction)
                    .buttonStyle(.bordered)
            }

            Text(command)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private var statusTitle: String {
        switch pickerProvider {
        case .ollama:
            return viewModel.ollamaSetupState.statusTitle
        case .cloudflare:
            return viewModel.isModelAvailable ? "Ready" : "Not configured"
        }
    }

    private var statusIcon: String {
        switch pickerProvider {
        case .ollama:
            return viewModel.ollamaSetupState.isReady ? "bolt.fill" : "bolt.slash.fill"
        case .cloudflare:
            return viewModel.isModelAvailable ? "bolt.fill" : "bolt.slash.fill"
        }
    }

    private var statusColor: Color {
        switch pickerProvider {
        case .ollama:
            return viewModel.ollamaSetupState.isReady ? .green : .orange
        case .cloudflare:
            return viewModel.isModelAvailable ? .green : .orange
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
