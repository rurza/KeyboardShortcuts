//
//  PreRecordingLabel.swift
//  
//
//  Created by Adam Różyński on 21/02/2024.
//

import SwiftUI

extension KeyboardShortcuts {
    struct PreRecordingLabel: View {
        @State private var lightBlinkingOpacity = 1.0
        let namespace: Namespace.ID

        var body: some View {
            HStack {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(Color.red)
                    .opacity(lightBlinkingOpacity)
                    .matchedGeometryEffect(id: GeometryID.dot, in: namespace)
                    .transition(.slide)
                Text("REC")
                    .font(.system(size: 11))
                    .fontWeight(.bold)
                    .kerning(1)
                    .matchedGeometryEffect(id: GeometryID.label, in: namespace)
            }
            .frame(width: 80, height: 26)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .stroke(.secondary, lineWidth: 0.5)
            )
            .matchedGeometryEffect(id: GeometryID.pill, in: namespace)
            .contentShape(Capsule())
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true).delay(0.7)) {
                    lightBlinkingOpacity = 0.05
                }
            }
        }
    }
}

#Preview {
    @Namespace var namespace
    return KeyboardShortcuts.PreRecordingLabel(namespace: namespace)
        .padding()
}
