//
//  FloatingPanelController.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import SwiftUI

/// Lightweight floating HUD (Raycast-style) for processing feedback.
@MainActor
final class FloatingPanelController: NSObject {
    static let shared = FloatingPanelController()

    private static let statusSize = NSSize(width: 420, height: 96)
    private static let previewSize = NSSize(width: 420, height: 340)

    private var panel: NSPanel?
    private var hostingView: NSHostingView<FloatingPanelView>?
    private var hideTask: Task<Void, Never>?

    private override init() {
        super.init()
    }

    func show(state: ProcessingState, nearMouse: Bool) {
        hideTask?.cancel()

        let panel = ensurePanel()
        applySize(for: state, to: panel)
        position(panel: panel, nearMouse: nearMouse)
        // Keep the user's app focused so ⌘V reaches their text field.
        panel.orderFrontRegardless()
    }

    func refresh(state: ProcessingState) {
        guard let panel, panel.isVisible else { return }
        applySize(for: state, to: panel)
        position(panel: panel, nearMouse: true)
    }

    func scheduleAutoHide(delay: TimeInterval = 1.6) {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            hide()
        }
    }

    func hide() {
        hideTask?.cancel()
        panel?.orderOut(nil)
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.statusSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let rootView = FloatingPanelView(processingState: ProcessingStateHolder.shared)
        let hosting = NSHostingView(rootView: rootView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hosting
        hostingView = hosting

        self.panel = panel
        return panel
    }

    private func applySize(for state: ProcessingState, to panel: NSPanel) {
        var targetSize = panelSize(for: state)
        hostingView?.layoutSubtreeIfNeeded()

        if let hostingView {
            let fittingSize = hostingView.fittingSize
            targetSize.width = max(targetSize.width, fittingSize.width)
            targetSize.height = max(targetSize.height, fittingSize.height)
        }

        var frame = panel.frame
        let previousOrigin = frame.origin
        frame.size = targetSize
        frame.origin = previousOrigin
        panel.setFrame(frame, display: true)
    }

    private func panelSize(for state: ProcessingState) -> NSSize {
        if case .preview = state.phase {
            return Self.previewSize
        }
        return Self.statusSize
    }

    private func position(panel: NSPanel, nearMouse: Bool) {
        panel.layoutIfNeeded()
        let size = panel.frame.size

        if nearMouse {
            let mouse = NSEvent.mouseLocation
            var origin = CGPoint(x: mouse.x + 16, y: mouse.y - size.height - 16)

            if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main {
                let frame = screen.visibleFrame
                origin.x = min(max(origin.x, frame.minX + 12), frame.maxX - size.width - 12)
                origin.y = min(max(origin.y, frame.minY + 12), frame.maxY - size.height - 12)
            }

            panel.setFrameOrigin(origin)
        } else if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let origin = CGPoint(
                x: frame.midX - size.width / 2,
                y: frame.midY - size.height / 2
            )
            panel.setFrameOrigin(origin)
        }
    }
}
