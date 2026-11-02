#if os(macOS)
import Foundation

/**
Hears a change to a shortcut's key in a store several processes share, whoever made it.

Key-value observing of `UserDefaults` is told by the preferences daemon of a write from any process, and by then the new value is readable here, which a notification posted beside the write could not promise.

A key containing a dot is never heard: key-value observing reads the dot as a key path, accepts the observer, and never calls it.
*/
final class StoreObserver: NSObject {
	private static var context = 0

	private let defaults: UserDefaults
	private let onChange: (String) -> Void
	private var keys = Set<String>()

	init(defaults: UserDefaults, onChange: @escaping (String) -> Void) {
		self.defaults = defaults
		self.onChange = onChange
	}

	func observe(_ key: String) {
		guard keys.insert(key).inserted else {
			return
		}

		if key.contains(".") {
			KeyboardShortcuts.logger.notice("\(key, privacy: .public) contains a dot, so a change another process makes to it is not heard")
		}

		defaults.addObserver(self, forKeyPath: key, options: [], context: &Self.context)
	}

	func invalidate() {
		for key in keys {
			defaults.removeObserver(self, forKeyPath: key, context: &Self.context)
		}

		keys.removeAll()
	}

	override func observeValue(
		forKeyPath keyPath: String?,
		of object: Any?,
		change: [NSKeyValueChangeKey: Any]?,
		context: UnsafeMutableRawPointer?
	) {
		guard context == &Self.context else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}

		guard let keyPath else {
			return
		}

		// Always on a later turn of the main run loop, so a write this process makes is finished — and its registrations made — before the change is looked at.
		DispatchQueue.main.async { [onChange] in
			onChange(keyPath)
		}
	}

	deinit {
		invalidate()
	}
}
#endif
