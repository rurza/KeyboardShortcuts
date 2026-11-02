import XCTest
@testable import KeyboardShortcuts

/// What another process is told about recording: an app whose recorder must make a shortcut's holder in another process let go hears when recording begins and ends.
final class RecordingNoticeTests: XCTestCase {
	func testRecordingIsReadableAndAnnouncedOnlyWhenItChanges() {
		let recorder1 = NSObject()
		let recorder2 = NSObject()
		var heard = [Bool]()
		let observer = NotificationCenter.default.addObserver(forName: KeyboardShortcuts.recordingDidChangeNotification, object: nil, queue: nil) { _ in
			heard.append(KeyboardShortcuts.isRecording)
		}
		defer { NotificationCenter.default.removeObserver(observer) }

		XCTAssertFalse(KeyboardShortcuts.isRecording)

		KeyboardShortcuts.setRecorder(recorder1, isPausing: true, reason: "test")
		KeyboardShortcuts.setRecorder(recorder2, isPausing: true, reason: "test")
		XCTAssertTrue(KeyboardShortcuts.isRecording)

		KeyboardShortcuts.setRecorder(recorder1, isPausing: false, reason: "test")
		KeyboardShortcuts.setRecorder(recorder2, isPausing: false, reason: "test")
		XCTAssertFalse(KeyboardShortcuts.isRecording)

		XCTAssertEqual(heard, [true, false])
	}

	@MainActor
	func testRemovingARecordingRecorderFromItsWindowIsAnnounced() {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: true)
		let recorder = RecorderContainerView(for: .init("testRemovingARecordingRecorderFromItsWindowIsAnnounced"))
		window.contentView?.addSubview(recorder)
		var heard = [Bool]()
		let observer = NotificationCenter.default.addObserver(forName: KeyboardShortcuts.recordingDidChangeNotification, object: nil, queue: nil) { _ in
			heard.append(KeyboardShortcuts.isRecording)
		}
		defer { NotificationCenter.default.removeObserver(observer) }

		recorder.startRecording()
		recorder.removeFromSuperview()

		XCTAssertEqual(heard, [true, false])
	}
}
