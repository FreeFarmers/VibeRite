//
//  HotkeyManager.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import AppKit
import Carbon
import Foundation

/// Registers a system-wide ⌘⇧F hotkey via Carbon Event Manager.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onTrigger: (() -> Void)?

    private let hotKeyID = EventHotKeyID(signature: OSType("VBRT".fourCharCodeValue), id: 1)

    private init() {}

    func register(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr, hotKeyID.id == manager.hotKeyID.id else {
                    return OSStatus(eventNotHandledErr)
                }

                DispatchQueue.main.async {
                    manager.onTrigger?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        RegisterEventHotKey(
            AppConstants.hotkeyKeyCode,
            AppConstants.hotkeyModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    deinit {
        unregister()
    }
}

private extension String {
    var fourCharCodeValue: OSType {
        var result: UInt32 = 0
        let padded = String(prefix(4))
        for char in padded.unicodeScalars {
            result = (result << 8) + UInt32(char.value)
        }
        while padded.count < 4 {
            result = result << 8
        }
        return OSType(result)
    }
}
