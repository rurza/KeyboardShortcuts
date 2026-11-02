import XCTest
import Carbon.HIToolbox
@testable import KeyboardShortcuts

/**
Letting go of every registered shortcut and taking them back, from outside any recorder.

This is what a process does while another process records the shortcut it holds: the system routes a registered hot key to the process holding it, so the recorder would never see the keystroke.
*/
final class LettingGoTests: XCTestCase {
	override func tearDown() {
		KeyboardShortcuts.isEnabled = true
		KeyboardShortcuts.removeAllHandlers()
	}

	func testDisablingLetsGoOfEveryRegisteredShortcutAndEnablingTakesThemBack() {
		let first = KeyboardShortcuts.Name("testDisablingLetsGoOfEveryRegisteredShortcut.first")
		let second = KeyboardShortcuts.Name("testDisablingLetsGoOfEveryRegisteredShortcut.second")
		let firstShortcut = KeyboardShortcuts.Shortcut(.f13, modifiers: [.control, .option])
		let secondShortcut = KeyboardShortcuts.Shortcut(.f14, modifiers: [.control, .option])
		KeyboardShortcuts.onKeyDown(for: first) {}
		KeyboardShortcuts.onKeyDown(for: second) {}
		KeyboardShortcuts.setShortcut(firstShortcut, for: first)
		KeyboardShortcuts.setShortcut(secondShortcut, for: second)
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(firstShortcut))
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(secondShortcut))
		XCTAssertFalse(canBeRegisteredBySomeoneElse(firstShortcut))

		KeyboardShortcuts.isEnabled = false

		XCTAssertFalse(CarbonKeyboardShortcuts.isRegistered(firstShortcut))
		XCTAssertFalse(CarbonKeyboardShortcuts.isRegistered(secondShortcut))
		XCTAssertTrue(canBeRegisteredBySomeoneElse(firstShortcut))
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: first), firstShortcut)

		KeyboardShortcuts.isEnabled = true

		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(firstShortcut))
		XCTAssertTrue(CarbonKeyboardShortcuts.isRegistered(secondShortcut))
		XCTAssertFalse(canBeRegisteredBySomeoneElse(firstShortcut))

		KeyboardShortcuts.setShortcut(nil, for: first)
		KeyboardShortcuts.setShortcut(nil, for: second)
	}

	/// Whether the system would give the chord to another registration, which it refuses while this package holds it.
	private func canBeRegisteredBySomeoneElse(_ shortcut: KeyboardShortcuts.Shortcut) -> Bool {
		var hotKey: EventHotKeyRef?
		let status = RegisterEventHotKey(
			UInt32(shortcut.carbonKeyCode),
			UInt32(shortcut.carbonModifiers),
			EventHotKeyID(signature: 0x54455354, id: 1), // "TEST"
			GetEventDispatcherTarget(),
			0,
			&hotKey
		)

		guard status == noErr, let hotKey else {
			return false
		}

		UnregisterEventHotKey(hotKey)
		return true
	}
}
