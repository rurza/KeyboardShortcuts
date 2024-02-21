//
//  File.swift
//  
//
//  Created by Adam Różyński on 21/02/2024.
//

import SwiftUI

extension KeyboardShortcuts {
    struct RecorderReadyLabel: View {
        var namespace: Namespace.ID

        var body: some View {
            Text("RECORD")
                .font(.system(size: 11))
                .fontWeight(.bold)
                .kerning(1)
                .frame(width: 80, height: 26)
//                .matchedGeometryEffect(id: GeometryID.label, in: namespace)
                .clipShape(.capsule)
                .overlay(
                    Capsule()
                        .stroke(.secondary, lineWidth: 0.5)
                )
                .matchedGeometryEffect(id: GeometryID.pill, in: namespace)
                .contentShape(Capsule())
        }
    }
}

#if DEBUG
#Preview {
    @Namespace var namespace
    return KeyboardShortcuts.RecorderReadyLabel(namespace: namespace)
        .padding()
}
#endif
