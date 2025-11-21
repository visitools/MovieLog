import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var logText: String = ""
    @State private var showPermissionAlert = false
    @State private var timerStartTime: Date = Date()
    @State private var useTimeOffset: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Text("MovieLog Timestamp Tracker")
                    .font(.title)
                    .fontWeight(.bold)

                // Permission Status
                HStack {
                    Circle()
                        .fill(hotkeyManager.hasAccessibilityPermissions ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)

                    Text(hotkeyManager.hasAccessibilityPermissions
                         ? "Global hotkey active"
                         : "Accessibility permission needed")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !hotkeyManager.hasAccessibilityPermissions {
                        Button("Check Permissions") {
                            hotkeyManager.checkAccessibilityPermissions()
                            if !hotkeyManager.hasAccessibilityPermissions {
                                showPermissionAlert = true
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            .padding()

            Divider()

            // Hotkey Recorder
            HotkeyRecorder(hotkeyManager: hotkeyManager) {
                // This closure is called when the hotkey is pressed
                appendTimestamp()
            }
            .padding(.horizontal)

            // Timer Controls
            VStack(spacing: 10) {
                HStack {
                    Toggle("Use time offset (HH:MM:SS)", isOn: $useTimeOffset)
                        .font(.body)

                    Spacer()

                    Button("Reset Timer") {
                        resetTimer()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if useTimeOffset {
                    Text("Timer started: \(formattedTimerStart)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Text Editor
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Timestamp Log")
                        .font(.headline)

                    Spacer()

                    Button("Copy") {
                        copyToClipboard()
                    }
                    .buttonStyle(.bordered)
                    .disabled(logText.isEmpty)

                    Button("Clear") {
                        logText = ""
                    }
                    .buttonStyle(.bordered)
                }

                TextEditor(text: $logText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 300)
                    .border(Color.gray.opacity(0.3), width: 1)
            }
            .padding()

            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions:")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("1. Click the hotkey button above and press a key combination (e.g., ⌘⇧T)")
                    .font(.caption)
                Text("2. Toggle between absolute timestamps or time offsets from timer reset")
                    .font(.caption)
                Text("3. Press your hotkey anywhere on your Mac to log entries")
                    .font(.caption)
                Text("   • Timestamp mode: YYYY-MM-DD HH:mm:ss")
                    .font(.caption)
                Text("   • Offset mode: HH:MM:SS (time since timer reset)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
        .onAppear {
            // Restore saved hotkey and register callback
            hotkeyManager.restoreHotkey {
                appendTimestamp()
            }
        }
        .alert("Accessibility Permission Required", isPresented: $showPermissionAlert) {
            Button("Open System Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("MovieLog needs accessibility permissions to monitor global hotkeys. Please enable it in System Settings > Privacy & Security > Accessibility.")
        }
    }

    private func appendTimestamp() {
        let entry: String

        if useTimeOffset {
            // Calculate time offset from timer start
            let offset = Date().timeIntervalSince(timerStartTime)
            entry = formatTimeOffset(offset)
        } else {
            // Use absolute timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            entry = formatter.string(from: Date())
        }

        DispatchQueue.main.async {
            if !logText.isEmpty && !logText.hasSuffix("\n") {
                logText += "\n"
            }
            logText += entry + "\n"
        }
    }

    private func resetTimer() {
        timerStartTime = Date()
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logText, forType: .string)
    }

    private func formatTimeOffset(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var formattedTimerStart: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timerStartTime)
    }
}
