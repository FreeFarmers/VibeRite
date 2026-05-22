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

    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    private override init() {
        super.init()
    }

    func show(state: ProcessingState, nearMouse: Bool) {
        hideTask?.cancel()

        let panel = ensurePanel()
        let rootView = FloatingPanelView(state: state)
        panel.contentView = NSHostingView(rootView: rootView)

        position(panel: panel, nearMouse: nearMouse)
        // Keep the user's app focused so ⌘V reaches their text field.
        panel.orderFrontRegardless()
    }

    func refresh(state: ProcessingState) {
        guard let panel, panel.isVisible else { return }
        panel.contentView = NSHostingView(rootView: FloatingPanelView(state: state))
        position(panel: panel, nearMouse: true)
    }

    func scheduleAutoHide(delay: TimeInterval = 1.6) {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            panel?.orderOut(nil)
        }
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 72),
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

        self.panel = panel
        return panel
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
