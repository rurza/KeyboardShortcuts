import XCTest
@testable import KeyboardShortcuts

/**
The choice of where shortcuts are stored, and hearing another process change one there.

Another process is played by `/usr/bin/defaults`, which writes through the same preferences daemon a second app would.
*/
final class SharedStoreTests: XCTestCase {
	private var suiteName = ""
	private var suite: UserDefaults!

	override func setUpWithError() throws {
		suiteName = "software.micropixels.keyboardshortcuts.tests.\(UUID().uuidString)"
		suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
	}

	override func tearDown() {
		KeyboardShortcuts.userDefaults = .standard
		suite.removePersistentDomain(forName: suiteName)
		suite = nil
	}

	func testTheStandardDefaultsAreTheStoreUnlessAnotherIsChosen() {
		XCTAssertTrue(KeyboardShortcuts.userDefaults === UserDefaults.standard)
	}

	func testAChosenStoreKeepsTheSameKeys() {
		let name = KeyboardShortcuts.Name("testAChosenStoreKeepsTheSameKeys")
		let shortcut = KeyboardShortcuts.Shortcut(.f17, modifiers: [.control, .option])
		KeyboardShortcuts.userDefaults = suite

		KeyboardShortcuts.setShortcut(shortcut, for: name)

		XCTAssertNotNil(suite.string(forKey: "KeyboardShortcuts_testAChosenStoreKeepsTheSameKeys"))
		XCTAssertNil(UserDefaults.standard.object(forKey: "KeyboardShortcuts_testAChosenStoreKeepsTheSameKeys"))
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: name), shortcut)

		KeyboardShortcuts.setShortcut(nil, for: name)
		XCTAssertNil(suite.object(forKey: "KeyboardShortcuts_testAChosenStoreKeepsTheSameKeys"))
	}

	func testADefaultShortcutIsWrittenToTheChosenStore() {
		let shortcut = KeyboardShortcuts.Shortcut(.f17, modifiers: [.control, .option, .shift])
		KeyboardShortcuts.userDefaults = suite

		let name = KeyboardShortcuts.Name("testADefaultShortcutIsWrittenToTheChosenStore", default: shortcut)

		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: name), shortcut)
		XCTAssertNotNil(suite.string(forKey: "KeyboardShortcuts_testADefaultShortcutIsWrittenToTheChosenStore"))
		XCTAssertNil(UserDefaults.standard.object(forKey: "KeyboardShortcuts_testADefaultShortcutIsWrittenToTheChosenStore"))

		KeyboardShortcuts.setShortcut(nil, for: name)
	}

	func testTheStandardStoreStillRegistersAShortcutNobodyListensFor() {
		let name = KeyboardShortcuts.Name("testTheStandardStoreStillRegistersAShortcutNobodyListensFor")
		let shortcut = KeyboardShortcuts.Shortcut(.f18, modifiers: [.control, .option])

		KeyboardShortcuts.setShortcut(shortcut, for: name)
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(shortcut))

		KeyboardShortcuts.setShortcut(nil, for: name)
		XCTAssertFalse(CarbonKeyboardShortcuts.isRegistered(shortcut))
	}

	func testASharedStoreRegistersOnlyShortcutsThisProcessListensFor() {
		let recorded = KeyboardShortcuts.Name("testASharedStoreRegistersOnlyShortcutsThisProcessListensFor.recorded")
		let listened = KeyboardShortcuts.Name("testASharedStoreRegistersOnlyShortcutsThisProcessListensFor.listened")
		let recordedShortcut = KeyboardShortcuts.Shortcut(.f18, modifiers: [.control, .option, .shift])
		let listenedShortcut = KeyboardShortcuts.Shortcut(.f19, modifiers: [.control, .option, .shift])
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: listened) {}

		KeyboardShortcuts.setShortcut(recordedShortcut, for: recorded)
		KeyboardShortcuts.setShortcut(listenedShortcut, for: listened)

		XCTAssertFalse(CarbonKeyboardShortcuts.isRegistered(recordedShortcut))
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(listenedShortcut))

		KeyboardShortcuts.setShortcut(nil, for: recorded)
		KeyboardShortcuts.setShortcut(nil, for: listened)
		KeyboardShortcuts.removeAllHandlers()
	}

	func testAShortcutAnotherProcessWritesIsHeardAndRegistered() throws {
		let name = KeyboardShortcuts.Name("testAShortcutAnotherProcessWritesIsHeardAndRegistered")
		let old = KeyboardShortcuts.Shortcut(.f16, modifiers: [.control, .option])
		let new = KeyboardShortcuts.Shortcut(.f16, modifiers: [.control, .option, .shift])
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: name) {}
		KeyboardShortcuts.setShortcut(old, for: name)
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(old))

		let heard = expectation(forNotification: .shortcutByNameDidChange, object: nil) { notification in
			(notification.userInfo?["name"] as? KeyboardShortcuts.Name) == name
		}
		let encoded = try XCTUnwrap(String(data: JSONEncoder().encode(new), encoding: .utf8))
		try runDefaults("write", suiteName, "KeyboardShortcuts_\(name.rawValue)", "-string", encoded)
		wait(for: [heard], timeout: 5)

		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: name), new)
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(new))
		XCTAssertFalse(CarbonKeyboardShortcuts.isRegistered(old))

		KeyboardShortcuts.setShortcut(nil, for: name)
		KeyboardShortcuts.removeAllHandlers()
	}

	func testAShortcutAnotherProcessClearsIsLetGo() throws {
		let name = KeyboardShortcuts.Name("testAShortcutAnotherProcessClearsIsLetGo")
		let shortcut = KeyboardShortcuts.Shortcut(.f15, modifiers: [.control, .option])
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: name) {}
		KeyboardShortcuts.setShortcut(shortcut, for: name)
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(shortcut))

		let heard = expectation(forNotification: .shortcutByNameDidChange, object: nil) { notification in
			(notification.userInfo?["name"] as? KeyboardShortcuts.Name) == name
		}
		try runDefaults("delete", suiteName, "KeyboardShortcuts_\(name.rawValue)")
		wait(for: [heard], timeout: 5)

		XCTAssertNil(KeyboardShortcuts.getShortcut(for: name))
		XCTAssertFalse(CarbonKeyboardShortcuts.isRegistered(shortcut))

		KeyboardShortcuts.removeAllHandlers()
	}

	func testANameThisProcessDisabledStaysDisabledWhenAnotherProcessChangesIt() throws {
		let name = KeyboardShortcuts.Name("testANameThisProcessDisabledStaysDisabledWhenAnotherProcessChangesIt")
		let old = KeyboardShortcuts.Shortcut(.f14, modifiers: [.control, .option, .shift])
		let new = KeyboardShortcuts.Shortcut(.f14, modifiers: [.control, .option, .command])
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: name) {}
		KeyboardShortcuts.setShortcut(old, for: name)
		KeyboardShortcuts.disable(name)

		let heard = expectation(forNotification: .shortcutByNameDidChange, object: nil) { notification in
			(notification.userInfo?["name"] as? KeyboardShortcuts.Name) == name
		}
		let encoded = try XCTUnwrap(String(data: JSONEncoder().encode(new), encoding: .utf8))
		try runDefaults("write", suiteName, "KeyboardShortcuts_\(name.rawValue)", "-string", encoded)
		wait(for: [heard], timeout: 5)

		XCTAssertFalse(CarbonKeyboardShortcuts.isRegistered(new))

		KeyboardShortcuts.setShortcut(nil, for: name)
		KeyboardShortcuts.removeAllHandlers()
	}

	func testTheStandardStoreDoesNotListenToOtherProcesses() throws {
		let name = KeyboardShortcuts.Name("testTheStandardStoreDoesNotListenToOtherProcesses")
		let shortcut = KeyboardShortcuts.Shortcut(.f15, modifiers: [.control, .option, .shift])
		KeyboardShortcuts.onKeyDown(for: name) {}
		KeyboardShortcuts.setShortcut(shortcut, for: name)

		XCTAssertFalse(KeyboardShortcuts.isObservingOtherProcesses)

		KeyboardShortcuts.setShortcut(nil, for: name)
		KeyboardShortcuts.removeAllHandlers()
	}

	private func runDefaults(_ arguments: String...) throws {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
		process.arguments = arguments
		try process.run()
		process.waitUntilExit()
		XCTAssertEqual(process.terminationStatus, 0)
	}
}
