import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let testShortcut1 = Self("testShortcut1")
    static let testShortcut2 = Self("testShortcut2")
    static let testShortcut3 = Self("testShortcut3")
}

private struct DoubleShortcut: View {
    @State private var isPressed1 = false
    @State private var isPressed2 = false
    @State private var isPressed3 = false

    var body: some View {
        Form {
            HStack {
                KeyboardShortcuts.Recorder(for: .testShortcut1)
                Spacer()
                Text("Pressed? \(isPressed1 ? "👍" : "👎")")
            }

            HStack {
                KeyboardShortcuts.Recorder(for: .testShortcut2)
                Spacer()
                Text("Pressed? \(isPressed2 ? "👍" : "👎")")
            }
            .padding()
            .background(Color(red: 249/255, green: 248/255, blue: 250/255))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.secondary.opacity(0.4), lineWidth: 0.5)
            }
            GroupBox {
                HStack {
                    KeyboardShortcuts.Recorder(for: .testShortcut3)
                    Spacer()
                    Text("Pressed? \(isPressed3 ? "👍" : "👎")")
                }
            }
            .padding(.vertical)
            Spacer()
            Button("Reset All") {
                KeyboardShortcuts.reset(.testShortcut1, .testShortcut2, .testShortcut3)
            }
        }
        .padding()
        .onKeyboardShortcut(.testShortcut1) {
            isPressed1 = $0 == .keyDown
        }
        .onKeyboardShortcut(.testShortcut2, type: .keyDown) {
            isPressed2 = true
        }
        .onKeyboardShortcut(.testShortcut3) {
            isPressed2 = $0 == .keyDown
        }
        .task {
            KeyboardShortcuts.onKeyUp(for: .testShortcut2) {
                isPressed2 = false
            }
        }
    }
}

struct MainScreen: View {
    var body: some View {
        VStack {
            DoubleShortcut()
        }
        .frame(width: 500, height: 320)
    }
}

#Preview {
    MainScreen()
}
