import SwiftUI

@MainActor
final class AppState: ObservableObject {
	func createMenus() {
		let testMenuItem = NSMenuItem()
		NSApp.mainMenu?.addItem(testMenuItem)

		let testMenu = NSMenu()
		testMenu.title = "Test"
		testMenuItem.submenu = testMenu

		testMenu.addCallbackItem("Shortcut 1") { [weak self] in
			self?.alert(1)
		}
			.setShortcut(for: .testShortcut1)

		testMenu.addCallbackItem("Shortcut 2") { [weak self] in
			self?.alert(2)
		}
			.setShortcut(for: .testShortcut2)

	}

	private func alert(_ number: Int) {
		let alert = NSAlert()
		alert.messageText = "Shortcut \(number) menu item action triggered!"
		alert.runModal()
	}
}
