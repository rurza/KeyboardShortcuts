import XCTest
import Carbon.HIToolbox
@testable import KeyboardShortcuts

/**
Whether the system holds a name's shortcut for this process — the answer a settings window in another process needs before it can say a shortcut is taken.
*/
final class HoldingTests: XCTestCase {
	private var suiteName = ""
	private var suite: UserDefaults!

	override func setUpWithError() throws {
		suiteName = "software.micropixels.keyboardshortcuts.tests.\(UUID().uuidString)"
		suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
	}

	override func tearDown() {
		KeyboardShortcuts.isEnabled = true
		KeyboardShortcuts.removeAllHandlers()
		KeyboardShortcuts.userDefaults = .standard
		suite.removePersistentDomain(forName: suiteName)
		suite = nil
	}

	func testAShortcutListenedForIsHeld() {
		let name = KeyboardShortcuts.Name("testAShortcutListenedForIsHeld")
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: name) {}

		KeyboardShortcuts.setShortcut(.init(.f13, modifiers: [.control, .option, .shift]), for: name)

		XCTAssertTrue(KeyboardShortcuts.isHeld(name))

		KeyboardShortcuts.setShortcut(nil, for: name)
	}

	func testANameWithNoShortcutIsNotHeld() {
		let name = KeyboardShortcuts.Name("testANameWithNoShortcutIsNotHeld")
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: name) {}

		XCTAssertFalse(KeyboardShortcuts.isHeld(name))
	}

	func testAShortcutNobodyHereListensForIsNotHeldInASharedStore() {
		let name = KeyboardShortcuts.Name("testAShortcutNobodyHereListensForIsNotHeldInASharedStore")
		KeyboardShortcuts.userDefaults = suite

		KeyboardShortcuts.setShortcut(.init(.f14, modifiers: [.control, .option, .shift]), for: name)

		XCTAssertFalse(KeyboardShortcuts.isHeld(name))

		KeyboardShortcuts.setShortcut(nil, for: name)
	}

	func testAShortcutTheSystemGaveToSomeoneElseIsNotHeld() throws {
		let name = KeyboardShortcuts.Name("testAShortcutTheSystemGaveToSomeoneElseIsNotHeld")
		let shortcut = KeyboardShortcuts.Shortcut(.f15, modifiers: [.control, .option, .shift])
		KeyboardShortcuts.userDefaults = suite
		let someoneElse = try XCTUnwrap(registerAsSomeoneElse(shortcut))
		defer { UnregisterEventHotKey(someoneElse) }
		KeyboardShortcuts.onKeyDown(for: name) {}

		KeyboardShortcuts.setShortcut(shortcut, for: name)

		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: name), shortcut)
		XCTAssertFalse(KeyboardShortcuts.isHeld(name))

		KeyboardShortcuts.setShortcut(nil, for: name)
	}

	func testAShortcutLetGoOfWhileDisabledIsNotHeld() {
		let name = KeyboardShortcuts.Name("testAShortcutLetGoOfWhileDisabledIsNotHeld")
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: name) {}
		KeyboardShortcuts.setShortcut(.init(.f16, modifiers: [.control, .option, .shift]), for: name)

		KeyboardShortcuts.isEnabled = false
		XCTAssertFalse(KeyboardShortcuts.isHeld(name))

		KeyboardShortcuts.isEnabled = true
		XCTAssertTrue(KeyboardShortcuts.isHeld(name))

		KeyboardShortcuts.setShortcut(nil, for: name)
	}

	func testTheChangeNoticeComesOnceAnotherProcessesShortcutIsHeld() throws {
		let name = KeyboardShortcuts.Name("testTheChangeNoticeComesOnceAnotherProcessesShortcutIsHeld")
		let old = KeyboardShortcuts.Shortcut(.f17, modifiers: [.control, .option, .shift])
		let new = KeyboardShortcuts.Shortcut(.f17, modifiers: [.control, .option, .command])
		KeyboardShortcuts.userDefaults = suite
		KeyboardShortcuts.onKeyDown(for: name) {}
		KeyboardShortcuts.setShortcut(old, for: name)

		var heldWhenTold: Bool?
		let heard = expectation(forNotification: KeyboardShortcuts.shortcutDidChangeNotification, object: nil) { notification in
			guard (notification.userInfo?["name"] as? KeyboardShortcuts.Name) == name else {
				return false
			}

			heldWhenTold = KeyboardShortcuts.getShortcut(for: name) == new && KeyboardShortcuts.isHeld(name)
			return true
		}
		let encoded = try XCTUnwrap(String(data: JSONEncoder().encode(new), encoding: .utf8))
		try runDefaults("write", suiteName, "KeyboardShortcuts_\(name.rawValue)", "-string", encoded)
		wait(for: [heard], timeout: 5)

		XCTAssertEqual(heldWhenTold, true)

		KeyboardShortcuts.setShortcut(nil, for: name)
	}

	/// The chord registered outside this package, as another app would hold it first.
	private func registerAsSomeoneElse(_ shortcut: KeyboardShortcuts.Shortcut) -> EventHotKeyRef? {
		var hotKey: EventHotKeyRef?
		let status = RegisterEventHotKey(
			UInt32(shortcut.carbonKeyCode),
			UInt32(shortcut.carbonModifiers),
			EventHotKeyID(signature: 0x54455354, id: 2), // "TEST"
			GetEventDispatcherTarget(),
			0,
			&hotKey
		)

		return status == noErr ? hotKey : nil
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
