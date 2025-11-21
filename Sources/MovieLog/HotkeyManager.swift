import Foundation
import Carbon
import AppKit

class HotkeyManager: ObservableObject {
    @Published var currentHotkey: String = "Not set"
    @Published var hasAccessibilityPermissions: Bool = false

    private var eventHotkey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var hotkeyCallback: (() -> Void)?

    private var keyCode: UInt32 = 0
    private var modifiers: UInt32 = 0

    static let shared = HotkeyManager()

    init() {
        checkAccessibilityPermissions()
        loadStoredHotkey()
    }

    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        hasAccessibilityPermissions = AXIsProcessTrustedWithOptions(options)
    }

    func registerHotkey(keyCode: UInt32, modifiers: UInt32, callback: @escaping () -> Void) {
        // Unregister existing hotkey first
        unregisterHotkey()

        self.keyCode = keyCode
        self.modifiers = modifiers
        self.hotkeyCallback = callback

        // Save to UserDefaults
        UserDefaults.standard.set(keyCode, forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(modifiers, forKey: "hotkeyModifiers")

        // Update display string
        currentHotkey = hotkeyString(keyCode: keyCode, modifiers: modifiers)

        // Register the hotkey
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.hotkeyCallback?()
            return noErr
        }, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandler)

        let hotkeyID = EventHotKeyID(signature: OSType(0x4D4C4F47), id: 1) // 'MLOG'
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &eventHotkey)

        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }

    func unregisterHotkey() {
        if let hotkey = eventHotkey {
            UnregisterEventHotKey(hotkey)
            eventHotkey = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    func loadStoredHotkey() {
        let storedKeyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32 ?? 0
        let storedModifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 ?? 0

        if storedKeyCode != 0 {
            self.keyCode = storedKeyCode
            self.modifiers = storedModifiers
            currentHotkey = hotkeyString(keyCode: storedKeyCode, modifiers: storedModifiers)
        }
    }

    func restoreHotkey(callback: @escaping () -> Void) {
        if keyCode != 0 {
            registerHotkey(keyCode: keyCode, modifiers: modifiers, callback: callback)
        }
    }

    private func hotkeyString(keyCode: UInt32, modifiers: UInt32) -> String {
        var components: [String] = []

        if modifiers & UInt32(controlKey) != 0 {
            components.append("⌃")
        }
        if modifiers & UInt32(optionKey) != 0 {
            components.append("⌥")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            components.append("⇧")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            components.append("⌘")
        }

        let keyString = keyCodeToString(keyCode) ?? "Unknown"
        components.append(keyString)

        return components.joined()
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        let keyCodeMap: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "Return", 48: "Tab", 51: "Delete", 53: "Escape",
            64: "F17", 79: "F18", 80: "F19", 90: "F20",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 105: "F13", 106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
            118: "F1", 120: "F2", 122: "F4"
        ]

        return keyCodeMap[keyCode]
    }
}
