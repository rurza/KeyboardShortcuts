import SwiftUI

extension KeyboardShortcuts {
    public struct Recorder: View {
        private let name: Name
        private let onChange: ((Shortcut?) -> Void)?
        @Namespace private var namespace

        public init(for name: KeyboardShortcuts.Name, onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil) {
            self.name = name
            self.onChange = onChange
        }

        @State private var isActive = false
        @State private var mode: RecorderMode = .ready
        @State private var size: CGSize = .zero

        static let backgroundLight = Color(red: 239/255, green: 238/255, blue: 240/255)
        static let backgroundDark = Color(red: 0.21, green: 0.19, blue: 0.23, opacity: 1.00)

        public var body: some View {
            ZStack {
                _Recorder(
                    name: name,
                    isActive: isActive,
                    modeChange: { mode in
                        guard mode != self.mode else { return }
                        print("mode did change ", mode, name)
                        self.mode = mode
                        if !mode.isActive {
                            isActive = false
                        }
                    },
                    onChange: onChange
                )
                .frame(width: 0, height: 0)
                HStack {
                    HStack {
                        switch mode {
                        case .ready:
                            Text("RECORD")
                                .commandStyle()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        case .preRecording:
                            HStack {
                                BlinkingLight()
                                Text("REC")
                                    .commandStyle()
                                    .foregroundStyle(Color.secondary)
                            }
                            .transition(.preRecording)

                        case .recording(let shortcut):
                            let shortcutArray = shortcut.map { String($0) }
                            HStack(spacing: 2) {
                                ForEach(shortcutArray, id: \.self) { symbol in
                                    ShortcutSymbol(symbol: symbol)
                                        .matchedGeometryEffect(id: GeometryID.symbol(symbol), in: namespace)
                                        .transition(
                                            .move(edge: .leading)
                                            .combined(with: .offset(x: -60))
                                            .combined(with: .opacity)
                                        )
                                }
                            }
                        case .set(let shortcut):
                            HStack(spacing: 2) {
                                let shortcutArray = shortcut.map { String($0) }

                                ForEach(shortcutArray, id: \.self) { symbol in
                                    if symbol.allSatisfy(\.isASCII) {
                                        Text("+")
                                            .shortcutStyle()
                                            .frame(width: 18)
                                    }
                                    ShortcutSymbol(symbol: symbol)
                                        .matchedGeometryEffect(id: GeometryID.symbol(symbol), in: namespace)
                                        .transition(
                                            .move(edge: .leading)
                                            .combined(with: .offset(x: -30)
                                                .combined(with: .opacity))
                                        )
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }

                    }
                    .padding(.horizontal, mode.thereIsNoKeys ? 8 : 2)
                    .frame(height: 26)
                    .frame(minWidth: 70)
                    .background(Self.backgroundLight)
                    .modify { view in
                        if mode.thereIsNoKeys {
                            view
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(.secondary, lineWidth: 0.5).opacity(0.3))
                                .contentShape(Capsule())
                        } else {
                            view
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(.secondary, lineWidth: 0.5).opacity(0.3))
                                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                    .matchedGeometryEffect(id: GeometryID.pill, in: namespace)
                    .onTapGesture {
                        if !mode.isActive {
                            print("on tap gesture ", name)
                            isActive = true
                        }
                    }
                    Button(
                        action: {
                            if mode.isActive {
                                isActive = false
                            } else if case .set = mode {
                                KeyboardShortcuts.reset([name])
                            }
                        },
                        label: {
                            Image(systemName: helperImageName)
                                .fontWeight(.bold)
                                .imageScale(.large)
                                .foregroundColor(Color.secondary)
                        }
                    )
                    .buttonStyle(.plain)
                    .opacity(mode == .ready ? 0 : 1)
                    .scaleEffect(mode == .ready ? 0.8 : 1)
                    .offset(x: mode == .ready ? -10 : 0)
                    .matchedGeometryEffect(id: GeometryID.cancel, in: namespace)
                }
            }
            .animation(.bouncy, value: mode)
        }

        var helperImageName: String {
            switch mode {
            case .ready, .preRecording, .recording:
                return "xmark.circle.fill"
            case .set:
                return "trash.circle.fill"
            }
        }
    }

    enum GeometryID: Hashable {
        case pill
        case cancel
        case symbol(String)
    }

    private struct ContentSize: PreferenceKey {
        static var defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            guard nextValue() != .zero else { return }
            value = nextValue()
        }
    }
}

extension View {
    func commandStyle() -> some View {
        self
            .font(.system(size: 11))
            .fontWeight(.medium)
            .kerning(1)
            .foregroundStyle(Color.secondary)
    }
}

#if DEBUG
#Preview {
    KeyboardShortcuts.Recorder(
        for: .init("test")
    )
    .padding()
}
#endif
