//
//  ClipboardManager.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Foundation

/// Snapshot-based clipboard helpers for accessibility-safe copy/paste workflows.
final class ClipboardManager {
    static let shared = ClipboardManager()

    private init() {}

    struct PasteboardSnapshot {
        let items: [[NSPasteboard.PasteboardType: Data]]
    }

    func snapshot() -> PasteboardSnapshot {
        let pasteboard = NSPasteboard.general
        let items = pasteboard.pasteboardItems?.map { item -> [NSPasteboard.PasteboardType: Data] in
            var map: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    map[type] = data
                }
            }
            return map
        } ?? []
        return PasteboardSnapshot(items: items)
    }

    func restore(_ snapshot: PasteboardSnapshot) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard !snapshot.items.isEmpty else { return }

        let restoredItems: [NSPasteboardItem] = snapshot.items.map { map in
            let item = NSPasteboardItem()
            for (type, data) in map {
                item.setData(data, forType: type)
            }
            return item
        }

        pasteboard.writeObjects(restoredItems)
    }

    func readString() -> String? {
        NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func writeString(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
