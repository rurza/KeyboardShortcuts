//
//  View+Condition.swift
//
//
//  Created by Adam Różyński on 22/02/2024.
//

import SwiftUI

extension View {
    func modify<Content>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}
