//
//  Recorder+Mode.swift
//  
//
//  Created by Adam Różyński on 18/02/2024.
//
#if os(macOS)

import Foundation

public extension KeyboardShortcuts {
    enum RecorderMode: Equatable {
        case ready
        case preRecording
        case recording(String)
        case set(String)

        var isActive: Bool {
            switch self {
            case .preRecording, .recording:
                return true
            case .ready, .set:
                return false
            }
        }

        var thereIsNoKeys: Bool {
            switch self {
            case .ready, .preRecording:
                return true
            case .recording, .set:
                return false
            }
        }
    }
}

#endif
