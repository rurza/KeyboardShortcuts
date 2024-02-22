//
//  SwiftUIView.swift
//  
//
//  Created by Adam Różyński on 22/02/2024.
//

import SwiftUI

extension KeyboardShortcuts {
    struct BlinkingLight: View {
        @State private var lightBlinkingOpacity = 1.0
        @State private var lightBlinkingRadius = 6.0

        var body: some View {
            ZStack {
                Group {
                    ZStack {
                        Circle()
                            .foregroundStyle(Color.black.opacity(0.2))
                            .offset(y: 2)
                            .blur(radius: 2)
                        Circle()
                            .blendMode(.destinationOut)
                            .foregroundStyle(Color.black)
                    }
                    .compositingGroup()
                    .opacity(abs(lightBlinkingOpacity - 1))

                    Circle()
                        .frame(
                            width: lightBlinkingOpacity == 1 ? 12 : 8,
                            height: lightBlinkingOpacity == 1 ? 12 : 8
                        )
                        .foregroundStyle(Color.red)
                        .opacity(lightBlinkingOpacity)
                        .blur(radius: lightBlinkingRadius)
                    Circle()
                        .foregroundStyle(Color.red)
                        .opacity(lightBlinkingOpacity)
                    Circle()
                        .stroke(.primary, lineWidth: 0.5)
                        .opacity(lightBlinkingOpacity == 1 ? 0.25 : 0.3)
                    Ellipse()
                        .foregroundStyle(Color.white)
                        .frame(width: 4, height: 2)
                        .offset(y: -2)
                        .opacity(lightBlinkingOpacity == 1 ? 0.1 : 0.3)
                }
                .frame(width: 8, height: 8)
            }
            .frame(width: 8, height: 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true).delay(0.7)) {
                    lightBlinkingOpacity = 0.05
                    lightBlinkingRadius = 2
                }
            }
            .onDisappear {
                lightBlinkingOpacity = 1
                lightBlinkingRadius = 6
            }
        }
    }
}

#Preview {
    KeyboardShortcuts.BlinkingLight()
        .padding()
}
