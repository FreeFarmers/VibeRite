# VibeRite
<<<<<<< HEAD

VibeRite is a native macOS writing assistant that improves selected text anywhere on your Mac using **local Ollama models**. No cloud APIs. Private by design.

## Requirements

- macOS 14 or later
- Xcode 15+
- [Ollama](https://ollama.com) 0.24+ running locally
- Accessibility permission for VibeRite

## Quick Start

### 1. Install and run Ollama

```bash
# Install from https://ollama.com if needed
ollama serve
```

In another terminal, pull the default model:

```bash
ollama pull llama3.2:3b
```

Other supported models (optional):

```bash
ollama pull llama3
ollama pull mistral
ollama pull gemma
```

Verify Ollama is reachable:

```bash
curl http://localhost:11434/api/tags
```

### 2. Build and run VibeRite

1. Open `VibeRite.xcodeproj` in Xcode.
2. Select the **VibeRite** scheme and your Mac as the destination.
3. Press **⌘R** to build and run.
4. Grant **Accessibility** when prompted (required for global hotkey and paste workflows).

### 3. Enable Services (right-click menu)

1. Open **System Settings → Keyboard → Keyboard Shortcuts → Services**.
2. Find **VibeRite** and enable the writing actions you want.
3. In supported apps, select text → right-click → **Services** → **VibeRite** → choose an action.

Works best in native and standard text fields (Notes, TextEdit, Mail, Safari, Slack, Xcode, Chrome, etc.).

### 4. Use the global shortcut

1. Select text in any app.
2. Press **⌘⇧F** to run **Improve Writing** (default hotkey action).
3. A small floating HUD shows progress; improved text is pasted automatically.

## Architecture

```
VibeRite/
├── App/                    # App entry, AppDelegate, floating HUD
├── Models/                 # WritingAction, OllamaModel, settings, state
├── Services/
│   ├── HotkeyManager       # Carbon global hotkey (⌘⇧F)
│   ├── ContextMenuManager  # NSServices registration
│   ├── ClipboardManager    # Pasteboard snapshot/restore
│   ├── AccessibilityManager
│   ├── OllamaService       # Local /api/generate streaming
│   ├── PromptTemplateService
│   ├── TextReplacementService
│   ├── PermissionsManager
│   └── WritingCoordinator  # End-to-end pipeline
├── ViewModels/             # MVVM (MainViewModel)
├── Views/                  # SwiftUI main window + HUD
└── Utilities/
```

**MVVM flow:** Views bind to `MainViewModel` → `WritingCoordinator` orchestrates capture → Ollama → replace → `ProcessingStateHolder` drives the floating panel.

**Hotkey path:** `HotkeyManager` → copy selection (⌘C via CGEvent) → Ollama → paste (⌘V) with clipboard restored afterward.

**Services path:** macOS passes selected text on the service pasteboard → Ollama → result written back to the same pasteboard.

## Permissions Guide

| Permission | Why | How |
|------------|-----|-----|
| **Accessibility** | Simulate ⌘C/⌘V and read selection system-wide | System Settings → Privacy & Security → Accessibility → enable **VibeRite** |
| **Network (outgoing)** | Talk to `localhost:11434` only | Granted via entitlements; no internet required |

VibeRite does **not** send text to the cloud. All inference runs through your local Ollama instance.

## Ollama Setup Guide

| Setting | Value |
|---------|--------|
| API | `http://localhost:11434/api/generate` |
| Default model | `llama3.2:3b` |
| Supported models | `llama3.2:3b`, `llama3`, `mistral`, `gemma` |
| Streaming | Enabled (NDJSON chunks) |

**Ollama not running:** The app shows a friendly error and suggests `ollama serve`.

**Model missing:** Pull the model, e.g. `ollama pull llama3`.

Switch models in the VibeRite main window (segmented control). Choice is persisted in `UserDefaults`.

## Troubleshooting

- **Nothing happens on ⌘⇧F:** Confirm Accessibility is enabled and VibeRite is running in the background.
- **“No text selected”:** Highlight text first; some apps block synthetic copy — try Services instead.
- **Services missing:** Rebuild the app, then re-check Keyboard Shortcuts → Services.
- **Slow responses:** Use a smaller model or shorter selections (12k character limit).

## Future Roadmap (structure-ready)

- Menu bar presence
- Custom prompts and shortcuts
- Preview / diff before replace
- Writing history
- Menu bar command palette

## License

Copyright © BitsVessel. All rights reserved.
=======
Native macOS writing assistant that improves selected text anywhere using local Ollama — a private and system-wide tool with no cloud connectivity.
>>>>>>> 1b722950d906ad68fb61baae6858a536c63377e6
