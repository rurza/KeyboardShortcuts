//
//  _Recorder.swift
//
//
//  Created by Adam Różyński on 22/02/2024.
//

import SwiftUI

struct _Recorder: NSViewRepresentable {
    // swiftlint:disable:this type_name
    typealias NSViewType = RecorderContainerView

    let name: KeyboardShortcuts.Name
    let isActive: Bool
    let modeChange: (KeyboardShortcuts.RecorderMode) -> Void
    let onChange: ((_ shortcut: KeyboardShortcuts.Shortcut?) -> Void)?

    public func makeNSView(context: Context) -> NSViewType {
        let view = RecorderContainerView(for: name, onChange: onChange)
        view.delegate = context.coordinator
        return view
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        context.coordinator.parent = self
        nsView.shortcutName = name
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
    }
}
