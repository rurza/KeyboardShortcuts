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
                .border(.red)
                .onPreferenceChange(ContentSize.self) { size in
                    self.size = size
                }
                .frame(width: size.width, height: size.height)
                label
                    .frame(width: 120, height: 40)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ContentSize.self, value: geometry.size)
                        }
                    )
                    .border(.yellow)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isActive.toggle()
            }
        }

        @ViewBuilder
        var label: some View {
            switch mode {
            case .ready:
                Text("RECORD")
            case .preRecording:
                HStack {
                    Circle().foregroundStyle(.red).frame(width: 8, height: 8)
                    Text("REC")
                }
            case .recording(let string):
                Text(string)
            case .set(let string):
                Text(string)
            }
        }
    }

    private struct ContentSize: PreferenceKey {
        static var defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            guard nextValue() != .zero else { return }
            value = nextValue()
        }
    }
}

#Preview {
    KeyboardShortcuts.Recorder(
        for: .init("test")
    )
}
