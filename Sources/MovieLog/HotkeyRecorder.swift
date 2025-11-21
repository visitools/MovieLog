import SwiftUI
import Carbon

struct HotkeyRecorder: View {
    @ObservedObject var hotkeyManager: HotkeyManager
    @State private var isRecording = false
    let onHotkeySet: () -> Void

    var body: some View {
        HStack {
            Text("Global Hotkey:")
                .foregroundColor(.secondary)

            Button(action: {
                isRecording = true
            }) {
                HStack {
                    Text(isRecording ? "Press a key combination..." : hotkeyManager.currentHotkey)
                        .frame(minWidth: 150)
                    if isRecording {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding(8)
                .background(isRecording ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .background(HotkeyRecorderRepresentable(
                isRecording: $isRecording,
                hotkeyManager: hotkeyManager,
                onHotkeySet: onHotkeySet
            ))
        }
    }
}

struct HotkeyRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    let hotkeyManager: HotkeyManager
    let onHotkeySet: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = HotkeyRecorderView()
        view.onKeyPress = { keyCode, modifiers in
            if isRecording {
                hotkeyManager.registerHotkey(keyCode: keyCode, modifiers: modifiers) {
                    onHotkeySet()
                }
                DispatchQueue.main.async {
                    isRecording = false
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let recorderView = nsView as? HotkeyRecorderView {
            recorderView.isListening = isRecording
            if isRecording {
                recorderView.window?.makeFirstResponder(recorderView)
            }
        }
    }
}

class HotkeyRecorderView: NSView {
    var onKeyPress: ((UInt32, UInt32) -> Void)?
    var isListening = false

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard isListening else {
            super.keyDown(with: event)
            return
        }

        let keyCode = UInt32(event.keyCode)
        var modifiers: UInt32 = 0

        if event.modifierFlags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if event.modifierFlags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if event.modifierFlags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        if event.modifierFlags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }

        // Require at least one modifier key for safety
        if modifiers != 0 {
            onKeyPress?(keyCode, modifiers)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        // Handle modifier-only keys
        if isListening {
            super.flagsChanged(with: event)
        }
    }
}
