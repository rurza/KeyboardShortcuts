//
//  Transition+.swift
//
//
//  Created by Adam Różyński on 22/02/2024.
//

import SwiftUI

extension AnyTransition {
    static var preRecording: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity).combined(with: .offset(.init(width: -20, height: 0))),
            removal: .move(edge: .leading).combined(with: .opacity).combined(with: .offset(.init(width: -20, height: 0)))
        )
    }
}
