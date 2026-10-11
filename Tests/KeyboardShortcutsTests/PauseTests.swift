import XCTest
@testable import KeyboardShortcuts

final class PauseTests: XCTestCase {
	func testPausedWhileAnyRecorderIsPausing() {
		let recorder1 = NSObject()
		let recorder2 = NSObject()

		XCTAssertFalse(KeyboardShortcuts.isPaused)

		KeyboardShortcuts.setRecorder(recorder1, isPausing: true, reason: "test")
		KeyboardShortcuts.setRecorder(recorder2, isPausing: true, reason: "test")
		XCTAssertTrue(KeyboardShortcuts.isPaused)

		KeyboardShortcuts.setRecorder(recorder1, isPausing: false, reason: "test")
		XCTAssertTrue(KeyboardShortcuts.isPaused)

		KeyboardShortcuts.setRecorder(recorder2, isPausing: false, reason: "test")
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	func testStoppingTwiceDoesNotUnpauseAnotherRecorder() {
		let recorder1 = NSObject()
		let recorder2 = NSObject()

		KeyboardShortcuts.setRecorder(recorder1, isPausing: true, reason: "test")
		KeyboardShortcuts.setRecorder(recorder1, isPausing: false, reason: "test")
		KeyboardShortcuts.setRecorder(recorder2, isPausing: true, reason: "test")
		KeyboardShortcuts.setRecorder(recorder1, isPausing: false, reason: "test")
		XCTAssertTrue(KeyboardShortcuts.isPaused)

		KeyboardShortcuts.setRecorder(recorder2, isPausing: false, reason: "test")
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	@MainActor
	func testRecorderUnpausesWhenAnotherViewTakesFirstResponder() {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: true)
		let recorder = RecorderContainerView(for: .init("testRecorderUnpausesWhenAnotherViewTakesFirstResponder"))
		let textField = NSTextField()
		window.contentView?.addSubview(recorder)
		window.contentView?.addSubview(textField)

		recorder.startRecording()
		XCTAssertTrue(window.firstResponder === recorder)
		XCTAssertTrue(KeyboardShortcuts.isPaused)

		window.makeFirstResponder(textField)
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	@MainActor
	func testRecorderUnpausesWhenStoppedWhileStillFirstResponder() {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: true)
		let recorder = RecorderContainerView(for: .init("testRecorderUnpausesWhenStoppedWhileStillFirstResponder"))
		window.contentView?.addSubview(recorder)

		recorder.startRecording()
		XCTAssertTrue(KeyboardShortcuts.isPaused)

		// What the SwiftUI recorder's cancel button does through `updateNSView`.
		recorder.stopRecording()
		XCTAssertTrue(window.firstResponder === recorder)
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}

	@MainActor
	func testRecorderUnpausesWhenRemovedFromWindow() {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: true)
		let recorder = RecorderContainerView(for: .init("testRecorderUnpausesWhenRemovedFromWindow"))
		window.contentView?.addSubview(recorder)

		recorder.startRecording()
		XCTAssertTrue(KeyboardShortcuts.isPaused)

		recorder.removeFromSuperview()
		XCTAssertFalse(KeyboardShortcuts.isPaused)
	}
}
