import XCTest
import Carbon.HIToolbox
@testable import KeyboardShortcuts

/**
The recorder driven from the keyboard: reached by Tab and focused without listening, started by Space or Return, given up on by Esc keeping the old shortcut, cleared by Delete.

Opt-in: a recorder that is not asked for it behaves as it always did.
*/
@MainActor
final class KeyboardRecorderTests: XCTestCase {
	private var window: NSWindow!
	private var shortcutName: KeyboardShortcuts.Name!
	private let oldShortcut = KeyboardShortcuts.Shortcut(.f20, modifiers: [.control, .option])

	override func setUp() {
		_ = NSApplication.shared
		window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 100), styleMask: [.titled], backing: .buffered, defer: true)
		shortcutName = KeyboardShortcuts.Name("KeyboardRecorderTests.\(UUID().uuidString)")
		KeyboardShortcuts.setShortcut(oldShortcut, for: shortcutName)
	}

	override func tearDown() {
		KeyboardShortcuts.setShortcut(nil, for: shortcutName)
		window.contentView?.subviews.forEach { $0.removeFromSuperview() }
		window = nil
	}

	private func keyboardRecorder() -> RecorderContainerView {
		let recorder = RecorderContainerView(for: shortcutName)
		recorder.isKeyboardNavigable = true
		window.contentView?.addSubview(recorder)
		return recorder
	}

	private func key(_ keyCode: Int, _ characters: String, modifiers: NSEvent.ModifierFlags = []) -> NSEvent {
		NSEvent.keyEvent(
			with: .keyDown,
			location: .zero,
			modifierFlags: modifiers,
			timestamp: 0,
			windowNumber: window.windowNumber,
			context: nil,
			characters: characters,
			charactersIgnoringModifiers: characters,
			isARepeat: false,
			keyCode: UInt16(keyCode)
		)!
	}

	private var space: NSEvent { key(kVK_Space, " ") }
	private var returnKey: NSEvent { key(kVK_Return, "\r") }
	private var escape: NSEvent { key(kVK_Escape, "\u{1B}") }
	private var delete: NSEvent { key(kVK_Delete, "\u{7F}") }
	private var tab: NSEvent { key(kVK_Tab, "\t") }

	func testTabReachesTheRecorderWithoutStartingIt() {
		let before = NSTextField()
		let after = NSTextField()
		window.contentView?.addSubview(before)
		let recorder = keyboardRecorder()
		window.contentView?.addSubview(after)
		before.nextKeyView = recorder
		recorder.nextKeyView = after
		window.makeFirstResponder(before)

		window.selectKeyView(following: before)

		XCTAssertTrue(window.firstResponder === recorder)
		XCTAssertFalse(recorder.mode.isActive)
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	func testTheRecorderIsAKeyViewWhetherOrNotFullKeyboardAccessIsOn() {
		let recorder = keyboardRecorder()

		XCTAssertTrue(recorder.canBecomeKeyView)
		XCTAssertTrue(recorder.acceptsFirstResponder)
	}

	func testARecorderNotAskedForItIsNoKeyViewUntilItRecords() {
		let recorder = RecorderContainerView(for: shortcutName)
		window.contentView?.addSubview(recorder)

		XCTAssertFalse(recorder.canBecomeKeyView)

		recorder.keyDown(with: space)
		XCTAssertFalse(recorder.mode.isActive)
	}

	func testSpaceStartsListening() {
		let recorder = keyboardRecorder()
		window.makeFirstResponder(recorder)

		recorder.keyDown(with: space)

		XCTAssertEqual(recorder.mode, .preRecording)
		XCTAssertTrue(KeyboardShortcuts.isPaused)
		recorder.stopRecording()
	}

	func testReturnStartsListening() {
		let recorder = keyboardRecorder()
		window.makeFirstResponder(recorder)

		recorder.keyDown(with: returnKey)

		XCTAssertEqual(recorder.mode, .preRecording)
		recorder.stopRecording()
	}

	func testEscapeGivesUpKeepingTheOldShortcutAndTheFocus() {
		let recorder = keyboardRecorder()
		window.makeFirstResponder(recorder)
		recorder.keyDown(with: space)

		XCTAssertTrue(recorder.performKeyEquivalent(with: escape))

		XCTAssertEqual(recorder.mode, .set(oldShortcut.description))
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName), oldShortcut)
		XCTAssertTrue(window.firstResponder === recorder)
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	func testDeleteClearsTheShortcutWhileFocused() {
		let recorder = keyboardRecorder()
		window.makeFirstResponder(recorder)

		recorder.keyDown(with: delete)

		XCTAssertNil(KeyboardShortcuts.getShortcut(for: shortcutName))
		XCTAssertEqual(recorder.mode, .ready)
		XCTAssertTrue(window.firstResponder === recorder)
	}

	func testDeleteClearsEvenAShortcutTheNameHasByDefault() {
		let defaulted = KeyboardShortcuts.Name("KeyboardRecorderTests.defaulted.\(UUID().uuidString)", default: oldShortcut)
		let recorder = RecorderContainerView(for: defaulted)
		recorder.isKeyboardNavigable = true
		window.contentView?.addSubview(recorder)
		window.makeFirstResponder(recorder)

		recorder.keyDown(with: delete)

		XCTAssertNil(KeyboardShortcuts.getShortcut(for: defaulted))
		UserDefaults.standard.removeObject(forKey: "KeyboardShortcuts_\(defaulted.rawValue)")
	}

	func testAChordIsRecordedAndTheRecorderKeepsTheFocus() {
		let recorder = keyboardRecorder()
		window.makeFirstResponder(recorder)
		recorder.keyDown(with: space)
		let chord = key(kVK_ANSI_K, "k", modifiers: [.control, .option, .shift])

		XCTAssertTrue(recorder.performKeyEquivalent(with: chord))

		let recorded = KeyboardShortcuts.Shortcut(.k, modifiers: [.control, .option, .shift])
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName), recorded)
		XCTAssertEqual(recorder.mode, .set(recorded.description))
		XCTAssertTrue(window.firstResponder === recorder)
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	func testAKeyWithoutModifiersKeepsListening() {
		let recorder = keyboardRecorder()
		window.makeFirstResponder(recorder)
		recorder.keyDown(with: space)

		_ = recorder.performKeyEquivalent(with: key(kVK_ANSI_K, "k"))
		recorder.keyDown(with: key(kVK_ANSI_K, "k"))

		XCTAssertTrue(recorder.mode.isActive)
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName), oldShortcut)
		recorder.stopRecording()
	}

	func testTabWhileListeningGivesUpAndMovesOn() {
		let recorder = keyboardRecorder()
		let after = NSTextField()
		window.contentView?.addSubview(after)
		recorder.nextKeyView = after
		window.makeFirstResponder(recorder)
		recorder.keyDown(with: space)

		XCTAssertTrue(recorder.performKeyEquivalent(with: tab))

		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName), oldShortcut)
		XCTAssertEqual(recorder.mode, .set(oldShortcut.description))
		XCTAssertFalse(window.firstResponder === recorder)
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	func testFocusIsReportedToTheView() {
		let recorder = keyboardRecorder()
		let delegate = FocusSpy()
		recorder.delegate = delegate

		window.makeFirstResponder(recorder)
		XCTAssertEqual(delegate.focus.last, true)

		window.makeFirstResponder(nil)
		XCTAssertEqual(delegate.focus.last, false)
	}
}

private final class FocusSpy: RecorderContainerDelegate {
	var focus = [Bool]()

	func recorderModeDidChange(_ mode: KeyboardShortcuts.RecorderMode) {}

	func recorderFocusDidChange(_ isFocused: Bool) {
		focus.append(isFocused)
	}
}
