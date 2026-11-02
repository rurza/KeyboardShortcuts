#if os(macOS)

import SwiftUI

extension KeyboardShortcuts {
	public struct Recorder: View {
		private let name: Name
		private let onChange: ((Shortcut?) -> Void)?
		@Namespace private var namespace
		@Environment(\.isEnabled) var isEnabled
		@Environment(\.isKeyboardNavigableRecorder) private var isKeyboardNavigable

		@State private var isActive = false
		@State private var mode: RecorderMode = .ready
		@State private var size: CGSize = .zero
		@State private var symbolName: String = "xmark.circle.fill"
		@State private var delayedResetTask: Task<Void, Never>?
		@State private var isFocused = false

		public init(for name: KeyboardShortcuts.Name, onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil) {
			self.name = name
			self.onChange = onChange
		}

		public var body: some View {
			ZStack {
				if !isKeyboardNavigable {
					recorder
						.frame(width: 0, height: 0)
				}
				HStack {
					pill
					if mode != .ready {
						Button(
							action: {
								if mode.isActive {
									isActive = false
								} else if case .set = mode {
									KeyboardShortcuts.reset([name])
									onChange?(nil)
								}
							},
							label: {
								Image(systemName: symbolName)
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

		private var cornerRadius: CGFloat { mode.thereIsNoKeys ? 13 : 6 }

		/// The AppKit view that takes the keystrokes.
		private var recorder: some View {
			_Recorder(
				name: name,
				isActive: isActive,
				isKeyboardNavigable: isKeyboardNavigable,
				modeChange: { mode in
					let oldMode = self.mode
					guard mode != self.mode else { return }
					self.mode = mode
					if !mode.isActive {
						isActive = false
					} else {
						// Listening the recorder started itself, from the keyboard, which the next update must not end.
						isActive = true
					}
					if case .set = mode, case .recording = oldMode {
						withAnimation(.default) {
							symbolName = "checkmark.circle.fill"
						}
						delayedResetTask = Task {
							try? await Task.sleep(nanoseconds: 1_500_000_000)
							guard !Task.isCancelled else { return }
							withAnimation(.default) {
								symbolName = "xmark.circle.fill"
							}
						}
					} else {
						delayedResetTask?.cancel()
						symbolName = "xmark.circle.fill"
					}
				},
				onChange: onChange,
				focusChange: { isFocused = $0 }
			)
		}

		private var pill: some View {
			ZStack {
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
							.fixedSize(horizontal: true, vertical: false)
					}
					.padding(.horizontal, 8)
					.transition(.asymmetric(
						insertion: .move(edge: .leading).combined(with: .opacity),
						removal: .move(edge: .leading).combined(with: .opacity)
					))

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
			// Driven from the keyboard, the AppKit view lies under the pill at its size, so that it has a place in the window's key-view loop; clicks still reach the pill.
			.background {
				if isKeyboardNavigable {
					recorder
				}
			}
			.visualEffect(.adaptive(.windowBackground))
			.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
			.overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(.secondary, lineWidth: 0.5).opacity(0.3))
			.overlay {
				if isKeyboardNavigable, isFocused {
					RoundedRectangle(cornerRadius: cornerRadius + 3, style: .continuous)
						.strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 3)
						.padding(-3)
						.allowsHitTesting(false)
				}
			}
			.contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
			.onTapGesture {
				if !mode.isActive {
					isActive = true
				}
			}
			.matchedGeometryEffect(id: GeometryID.pill, in: namespace)
		}

		var tooltip: String {
			switch mode {
			case .ready, .set:
				return "record_shortcut".localized
			case .preRecording, .recording:
				return "press_shortcut".localized
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
	.padding(50)
}
#endif

#endif
