import XCTest
import SwiftUI
@testable import KeyboardShortcuts

/**
The SwiftUI recorder asked to be driven from the keyboard, inside a hosting view as a settings window holds it.
*/
@MainActor
final class SwiftUIRecorderTests: XCTestCase {
	private var window: NSWindow!
	private var shortcutName: KeyboardShortcuts.Name!

	override func setUp() {
		_ = NSApplication.shared
		shortcutName = KeyboardShortcuts.Name("SwiftUIRecorderTests.\(UUID().uuidString)")
	}

	override func tearDown() {
		KeyboardShortcuts.setShortcut(nil, for: shortcutName)
		window?.close()
		window = nil
	}

	private func host(_ view: some View) -> NSView {
		let hosting = NSHostingView(rootView: view.frame(width: 300, height: 200))
		window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200), styleMask: [.titled], backing: .buffered, defer: false)
		window.isReleasedWhenClosed = false
		window.contentView = hosting
		hosting.layoutSubtreeIfNeeded()
		return hosting
	}

	func testTheModifierMakesTheRecorderKeyboardNavigable() throws {
		let hosting = host(KeyboardShortcuts.Recorder(for: shortcutName).keyboardNavigableRecorder())

		let recorder = try XCTUnwrap(hosting.descendants(of: RecorderContainerView.self).first)
		XCTAssertTrue(recorder.isKeyboardNavigable)
		XCTAssertTrue(recorder.canBecomeKeyView)
	}

	func testARecorderWithoutTheModifierIsAsItWas() throws {
		let hosting = host(KeyboardShortcuts.Recorder(for: shortcutName))

		let recorder = try XCTUnwrap(hosting.descendants(of: RecorderContainerView.self).first)
		XCTAssertFalse(recorder.isKeyboardNavigable)
		XCTAssertFalse(recorder.canBecomeKeyView)
	}

	func testTabFromAFieldReachesTheRecorder() throws {
		let hosting = host(
			VStack {
				TextField("Before", text: .constant(""))
				KeyboardShortcuts.Recorder(for: shortcutName)
					.keyboardNavigableRecorder()
				TextField("After", text: .constant(""))
			}
		)
		let before = try XCTUnwrap(hosting.descendants(of: NSTextField.self).first)
		let recorder = try XCTUnwrap(hosting.descendants(of: RecorderContainerView.self).first)
		window.makeFirstResponder(before)

		window.selectKeyView(following: before)

		XCTAssertTrue(window.firstResponder === recorder, "first responder is \(String(describing: window.firstResponder)); Full Keyboard Access is \(NSApp.isFullKeyboardAccessEnabled ? "on" : "off")")
	}

	func testListeningStartedFromTheKeyboardIsNotEndedByTheView() throws {
		let hosting = host(KeyboardShortcuts.Recorder(for: shortcutName).keyboardNavigableRecorder())
		let recorder = try XCTUnwrap(hosting.descendants(of: RecorderContainerView.self).first)
		window.makeFirstResponder(recorder)

		recorder.keyDown(with: NSEvent.keyEvent(
			with: .keyDown,
			location: .zero,
			modifierFlags: [],
			timestamp: 0,
			windowNumber: window.windowNumber,
			context: nil,
			characters: " ",
			charactersIgnoringModifiers: " ",
			isARepeat: false,
			keyCode: 49
		)!)
		// Let the view hear of the change and update.
		RunLoop.main.run(until: Date().addingTimeInterval(0.3))
		hosting.layoutSubtreeIfNeeded()

		XCTAssertTrue(recorder.mode.isActive)
		recorder.stopRecording()
	}
}

extension NSView {
	fileprivate func descendants<T: NSView>(of type: T.Type) -> [T] {
		subviews.flatMap { subview -> [T] in
			(subview as? T).map { [$0] + subview.descendants(of: type) } ?? subview.descendants(of: type)
		}
	}
}
