import AppKit
import Carbon.HIToolbox

protocol RecorderContainerDelegate: AnyObject {
//    func recordingDidEnd()
    func recorderModeDidChange(_ mode: KeyboardShortcuts.RecorderMode)
}

extension KeyboardShortcuts {
    final class RecorderContainerView: NSView {
        private let onChange: ((_ shortcut: Shortcut?) -> Void)?
        var oldSet: String?
        var mode: RecorderMode = .ready {
            willSet {
                if case let .set(string) = mode, case .preRecording = newValue {
                    oldSet = string
                } else if case .set = newValue {
                    oldSet = nil
                }
            }
            didSet {
                // the delegate method will trigger UI update
                DispatchQueue.main.async {
                    self.delegate?.recorderModeDidChange(self.mode)
                }
            }
        }
        var active = false {
            didSet {
                guard oldValue != active else { return }
                if active {
                    mode = .preRecording
                    focus()
                } else {
                    if let oldSet {
                        mode = .set(oldSet)
                    } else if case .preRecording = mode {
                        mode = .ready
                    } else if case .recording = mode {
                        mode = .ready
                    }

                    blur()
                }
            }
        }
        
        var delegate: RecorderContainerDelegate?
        private var shortcutsNameChangeObserver: NSObjectProtocol?
        private var windowDidResignKeyObserver: NSObjectProtocol?
        
        /**
         The shortcut name for the recorder.
         
         Can be dynamically changed at any time.
         */
        var shortcutName: Name {
            didSet {
                guard shortcutName != oldValue else {
                    return
                }
                
                setStringValue(name: shortcutName)
                
                // This doesn't seem to be needed anymore, but I cannot test on older OS versions, so keeping it just in case.
                if #unavailable(macOS 12) {
                    DispatchQueue.main.async { [self] in
                        // Prevents the placeholder from being cut off.
                        blur()
                    }
                }
            }
        }
        
        /// :nodoc:
        override var canBecomeKeyView: Bool { true }

        required init(
            for name: Name,
            onChange: ((_ shortcut: Shortcut?) -> Void)? = nil
        ) {
            self.shortcutName = name
            self.onChange = onChange
            
            super.init(frame: .zero)
            
            
            self.wantsLayer = true
            setContentHuggingPriority(.defaultHigh, for: .vertical)
            setContentHuggingPriority(.defaultHigh, for: .horizontal)

            setUpEvents()
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setStringValue(name: KeyboardShortcuts.Name) {
            if let shortcut = getShortcut(for: name).map({ "\($0)" }) {
                mode = .set(shortcut)
            }
        }
        
        private func setUpEvents() {
            shortcutsNameChangeObserver = NotificationCenter.default.addObserver(forName: .shortcutByNameDidChange, object: nil, queue: nil) { [weak self] notification in
                guard
                    let self,
                    let nameInNotification = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
                    nameInNotification == self.shortcutName
                else {
                    return
                }
                
                self.setStringValue(name: nameInNotification)
            }
        }
        
        private func endRecording() {
            KeyboardShortcuts.isPaused = false
            blur()
//            active = false
        }
        
        /// :nodoc:
        override func viewDidMoveToWindow() {
            guard let window else {
                windowDidResignKeyObserver = nil
                endRecording()
                return
            }

            setStringValue(name: shortcutName) // set here, not in the init so the property observer will be called

            // Ensures the recorder stops when the window is hidden.
            // This is especially important for Settings windows, which as of macOS 13.5, 
            // only hides instead of closes when you click the close button.
            windowDidResignKeyObserver = NotificationCenter.default
                .addObserver(
                    forName: NSWindow.didResignKeyNotification,
                    object: window,
                    queue: nil
                ) { [weak self] _ in
                guard
                    let self,
                    let window = self.window
                else {
                    return
                }
                    self.endRecording()
                    if case .preRecording = mode {
                        self.mode = .ready
                    } else if case .recording = mode {
                        self.mode = .ready
                    }
                    window.makeFirstResponder(nil)
                }

        }


        // in this method the event won't have modifiers, only the character
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            guard active else { return false }
            guard !onlyTabPressed(event) else {
                endRecording()
                mode = .ready
                return true
            }

            guard !onlyEscapePressed(event) else {
                endRecording()
                if let oldSet {
                    mode = .set(oldSet)
                } else {
                    mode = .ready
                }
                return true
            }

            guard !onlyDeletePressed(event) else {
                endRecording()
                saveShortcut(nil)
                return true
            }

            guard !shiftOrFnIsTheOnlyModifier(event) else {
                mode = .preRecording
                return false
            }

            guard !event.modifiers.isEmpty, let shortcut = Shortcut(event: event) else {
                endRecording()
                mode = .ready
                return false
            }


            if let menuItem = shortcut.takenByMainMenu {
                endRecording()
                mode = .ready

                NSAlert.showModal(
                    for: self.window,
                    title: String.localizedStringWithFormat("keyboard_shortcut_used_by_menu_item".localized, menuItem.title)
                )
                return true
            }

            if shortcut.isTakenBySystem {
                endRecording()
                mode = .ready

                NSAlert.showModal(
                    for: self.window,
                    title: "keyboard_shortcut_used_by_system".localized,
                    // TODO: Add button to offer to open the relevant system settings pane for the user.
                    message: "keyboard_shortcuts_can_be_changed".localized,
                    buttonTitles: [
                        "ok".localized,
                        "force_use_shortcut".localized
                    ]
                )
                return true
            }

            saveShortcut(shortcut)
            return false
        }
        
        // can't user characters in here, but we have the access to modifiers
        override func flagsChanged(with event: NSEvent) {
            guard active else { return }
            print("<< flagsChanged, modifiers: \(event.modifiers)")
            if event.modifiers.isEmpty {
                mode = .preRecording
            } else {
                mode = .recording(event.modifiers.description)
            }
        }


        private func onlyEscapePressed(_ event: NSEvent) -> Bool {
            event.modifiers.isEmpty && event.keyCode == kVK_Escape
        }

        private func onlyTabPressed(_ event: NSEvent) -> Bool {
            event.modifiers.isEmpty && event.specialKey == .tab
        }

        /// The “shift” key is not allowed without other modifiers or a function key, since it doesn't actually work.
        private func shiftOrFnIsTheOnlyModifier(_ event: NSEvent) -> Bool {
            event.modifiers.subtracting(.shift).isEmpty || event.specialKey?.isFunctionKey == true
        }

        private func onlyDeletePressed(_ event: NSEvent) -> Bool {
            event.modifiers.isEmpty && (
                event.specialKey == .delete
                || event.specialKey == .deleteForward
                || event.specialKey == .backspace
            )
        }

        override func becomeFirstResponder() -> Bool {
            let shouldBecomeFirstResponder = super.becomeFirstResponder()

            guard shouldBecomeFirstResponder else {
                return shouldBecomeFirstResponder
            }

            KeyboardShortcuts.isPaused = true // The position here matters.
            return shouldBecomeFirstResponder
        }
        
        private func saveShortcut(_ shortcut: Shortcut?) {
            endRecording()
            if let shortcut {
                mode = .set(shortcut.description)
            } else {
                oldSet = nil
                mode = .ready
            }
            setShortcut(shortcut, for: shortcutName)
            onChange?(shortcut)
        }
    }
}
