//
//  _Recorder.swift
//
//
//  Created by Adam Różyński on 22/02/2024.
//
#if os(macOS)

import SwiftUI

struct _Recorder: NSViewRepresentable {
    // swiftlint:disable:this type_name
    typealias NSViewType = RecorderContainerView

    let name: KeyboardShortcuts.Name
    let isActive: Bool
    var isKeyboardNavigable = false
    let modeChange: (KeyboardShortcuts.RecorderMode) -> Void
    let onChange: ((_ shortcut: KeyboardShortcuts.Shortcut?) -> Void)?
    var focusChange: (Bool) -> Void = { _ in }

    public func makeNSView(context: Context) -> NSViewType {
        let view = RecorderContainerView(for: name, onChange: onChange)
        view.isKeyboardNavigable = isKeyboardNavigable
        view.delegate = context.coordinator
        return view
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        context.coordinator.parent = self
        nsView.shortcutName = name
        nsView.isKeyboardNavigable = isKeyboardNavigable
        if isActive {
            nsView.startRecording()
        } else {
            nsView.stopRecording()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator: RecorderContainerDelegate {
        var parent: _Recorder

        init(_ parent: _Recorder) {
            self.parent = parent
        }

        func recorderModeDidChange(_ mode: KeyboardShortcuts.RecorderMode) {
            self.parent.modeChange(mode)
        }

        func recorderFocusDidChange(_ isFocused: Bool) {
            // Later, as a first responder changes while AppKit is mid-event and possibly while SwiftUI updates the view.
            DispatchQueue.main.async {
                self.parent.focusChange(isFocused)
            }
        }
    }
}

#endif
