#if os(macOS)
import SwiftUI

extension View {
	/**
	Let every `KeyboardShortcuts.Recorder` inside this view be driven from the keyboard as well as by the mouse.

	Tab reaches the recorder whatever the system's keyboard-navigation setting, and it is then focused without listening, with a focus ring. Space or Return starts listening, Esc gives up and keeps the old shortcut, Delete clears the shortcut, and Tab gives up and moves on. Its ✕ clears the shortcut as Delete does, where a recorder without the modifier resets it to the name's default. Recording a shortcut, or giving up, leaves the recorder focused.

	A recorder outside such a view is reached by Tab only while it listens, as before.
	*/
	public func keyboardNavigableRecorder(_ isNavigable: Bool = true) -> some View {
		environment(\.isKeyboardNavigableRecorder, isNavigable)
	}
}

private struct KeyboardNavigableRecorderKey: EnvironmentKey {
	static let defaultValue = false
}

extension EnvironmentValues {
	var isKeyboardNavigableRecorder: Bool {
		get { self[KeyboardNavigableRecorderKey.self] }
		set { self[KeyboardNavigableRecorderKey.self] = newValue }
	}
}

@available(macOS 12, *)
extension View {
	/**
	Register a listener for keyboard shortcut events with the given name.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	The listener will stop automatically when the view disappears.

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	@MainActor
	public func onKeyboardShortcut(
		_ shortcut: KeyboardShortcuts.Name,
		perform: @escaping (KeyboardShortcuts.EventType) -> Void
	) -> some View {
		task {
			for await eventType in KeyboardShortcuts.events(for: shortcut) {
				perform(eventType)
			}
		}
	}

	/**
	Register a listener for keyboard shortcut events with the given name and type.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	The listener will stop automatically when the view disappears.

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	@MainActor
	public func onKeyboardShortcut(
		_ shortcut: KeyboardShortcuts.Name,
		type: KeyboardShortcuts.EventType,
		perform: @escaping () -> Void
	) -> some View {
		task {
			for await _ in KeyboardShortcuts.events(type, for: shortcut) {
				perform()
			}
		}
	}
}
#endif
