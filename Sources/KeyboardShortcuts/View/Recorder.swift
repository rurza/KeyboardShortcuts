#if os(macOS)

import SwiftUI

extension KeyboardShortcuts {
    public struct Recorder: View {
        private let name: Name
        private let onChange: ((Shortcut?) -> Void)?
        @Namespace private var namespace
        @Environment(\.isEnabled) var isEnabled

        @State private var isActive = false
        @State private var mode: RecorderMode = .ready
        @State private var size: CGSize = .zero

        public init(for name: KeyboardShortcuts.Name, onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil) {
            self.name = name
            self.onChange = onChange
        }

        public var body: some View {
            ZStack {
                _Recorder(
                    name: name,
                    isActive: isActive,
                    modeChange: { mode in
                        guard mode != self.mode else { return }
                        self.mode = mode
                        if !mode.isActive {
                            isActive = false
                        }
                    },
                    onChange: onChange
                )
                .frame(width: 0, height: 0)
                HStack {
                    ZStack {
                        HStack {
                            BlinkingLight()
                            Text("REC")
                                .commandStyle()
                                .foregroundStyle(Color.secondary)
                        }
                        .opacity(mode == .preRecording ? 1 : 0)
                        .offset(x: preRecordingLabelXOffset)
                        switch mode {
                        case .ready:
                            Text("RECORD")
                                .commandStyle()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        case .preRecording:
                            EmptyView()

                        case .recording(let shortcut), .set(let shortcut):
                            let shortcutArray = shortcut.map { String($0) }
                            HStack(spacing: 2) {
                                ForEach(shortcutArray, id: \.self) { symbol in
                                    ShortcutSymbol(symbol: symbol)
                                        .matchedGeometryEffect(id: GeometryID.symbol(symbol), in: namespace)
                                        .transition(
                                            .move(edge: .leading)
                                            .combined(with: .opacity)
                                        )
                                }
                            }
                            .id(GeometryID.shortcut)
                            .transition(
                                .offset(x: -30)
                                .combined(with: .opacity)
                            )
                            .matchedGeometryEffect(id: GeometryID.shortcut, in: namespace)
                        }
                    }
                    .padding(.horizontal, mode.thereIsNoKeys ? 8 : 2)
                    .frame(height: 26)
                    .frame(minWidth: 70)
                    
                    .visualEffect(.adaptive(.windowBackground))
                    .clipShape(RoundedRectangle(cornerRadius: mode.thereIsNoKeys ? 13 : 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: mode.thereIsNoKeys ? 13 : 6, style: .continuous).stroke(.secondary, lineWidth: 0.5).opacity(0.3))
                        .contentShape(RoundedRectangle(cornerRadius: mode.thereIsNoKeys ? 13 : 6, style: .continuous))
                    .onTapGesture {
                        if !mode.isActive {
                            isActive = true
                        }
                    }
                    .matchedGeometryEffect(id: GeometryID.pill, in: namespace)

                    if mode != .ready {
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
                        .matchedGeometryEffect(id: GeometryID.cancel, in: namespace)
                        .transition(.scale.combined(with: .opacity).combined(with: .offset(x: -30)))
                    }
                }
            }
            .animation(.spring(duration: 0.4), value: mode)
            .help(tooltip)
        }

        var tooltip: String {
            switch mode {
            case .ready, .set:
                return "record_shortcut".localized
            case .preRecording, .recording:
                return "press_shortcut".localized
            }
        }

        var helperImageName: String {
            switch mode {
            case .ready, .preRecording, .recording:
                return "xmark.circle.fill"
            case .set:
                return "trash.circle.fill"
            }
        }

        var preRecordingLabelXOffset: CGFloat {
            switch mode {
            case .ready:
                return -100
            case .preRecording:
                return 0
            case .recording:
                return 120
            case .set:
                return -120
            }
        }
    }

    enum GeometryID: Hashable {
        case pill
        case cancel
        case symbol(String)
        case shortcut
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

#endif
