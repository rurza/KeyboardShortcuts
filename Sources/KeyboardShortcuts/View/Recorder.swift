import SwiftUI

extension KeyboardShortcuts {
    struct _Recorder: NSViewRepresentable {
        // swiftlint:disable:this type_name
        typealias NSViewType = RecorderContainerView

        let name: Name
        let isActive: Bool
        let modeChange: (RecorderMode) -> Void
        let onChange: ((_ shortcut: Shortcut?) -> Void)?

        public func makeNSView(context: Context) -> NSViewType {
            print(#function)
            let view = RecorderContainerView(for: name, onChange: onChange)
            view.delegate = context.coordinator
            return view
        }

        public func updateNSView(_ nsView: NSViewType, context: Context) {
            print(#function)
            context.coordinator.parent = self
            nsView.shortcutName = name
            if isActive {
                nsView.startRecording()
            } else {
                nsView.stopRecording()
            }
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        public final class Coordinator: RecorderContainerDelegate {
            var parent: _Recorder

            init(_ parent: _Recorder) {
                self.parent = parent
            }

            func recorderModeDidChange(_ mode: KeyboardShortcuts.RecorderMode) {
                self.parent.modeChange(mode)
            }
        }
    }

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

        public var body: some View {
            ZStack {
                _Recorder(
                    name: name,
                    isActive: isActive,
                    modeChange: { mode in
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
                        if mode == .preRecording {
                            BlinkingLight()
                                .matchedGeometryEffect(id: GeometryID.dot, in: namespace)
                                .transition(.asymmetric(insertion: .slide, removal: .identity))
                        }

                        Text(mode == .ready ? "RECORD" : "REC")
                            .font(.system(size: 11))
                            .fontWeight(.bold)
                            .kerning(1)
                            .animation(nil, value: mode)
                    }
                    .padding(.horizontal, 8)
                    .frame(width: 80, height: 26)
                    .clipShape(.capsule)
                    .overlay(
                        Capsule()
                            .stroke(.secondary, lineWidth: 0.5)
                    )
                    .matchedGeometryEffect(id: GeometryID.pill, in: namespace)
                    .contentShape(Capsule())
                    .onTapGesture {
                        if !mode.isActive {
                            isActive = true
                        }
                    }
                    Button(
                        action: { isActive = false },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .fontWeight(.bold)
                                .imageScale(.large)
                                .foregroundColor(Color.secondary)
                        }
                    )
                    .buttonStyle(.plain)
                    .opacity(mode == .preRecording ? 1 : 0)
                    .scaleEffect(mode == .preRecording ? 1 : 0.8)
                    .offset(x: mode == .ready ? -10 : 0)
                    .animation(mode == .preRecording ? .spring : .easeInOut(duration: 0.1), value: mode)
                    .matchedGeometryEffect(id: GeometryID.cancel, in: namespace)
                }
            }

            .animation(.spring, value: mode)
        }

        @ViewBuilder
        var label: some View {
            switch mode {
            case .ready:
                RecorderReadyLabel(namespace: namespace)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isActive.toggle()
                    }
            case .preRecording:
                HStack {
                    PreRecordingLabel(namespace: namespace)
                    Button(
                        action: { isActive = false },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                        }
                    )
                    .buttonStyle(.plain)
                    .transition(.push(from: .trailing))
                    .matchedGeometryEffect(id: GeometryID.cancel, in: namespace)
                }

            case .recording(let string):
                Text(string)
            case .set(let string):
                Text(string)
            }
        }

    }

    enum GeometryID: Hashable {
        case pill
        case label
        case dot
        case cancel
    }

    private struct ContentSize: PreferenceKey {
        static var defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            guard nextValue() != .zero else { return }
            value = nextValue()
        }
    }
}

#if DEBG
#Preview {
    KeyboardShortcuts.Recorder(
        for: .init("test")
    )
}
#endif
