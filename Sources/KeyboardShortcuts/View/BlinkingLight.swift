//
//  SwiftUIView.swift
//
//
//  Created by Adam Różyński on 22/02/2024.
//

import SwiftUI


struct BlinkingLight: View {
    @State private var lightBlinkingOpacity = 1.0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Group {
                ZStack { // shadow
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

                Circle() // light blur
                    .foregroundStyle(Color.red)
                    .opacity(lightBlinkingOpacity)
                    .blur(radius: 4)
                Circle() // light
                    .foregroundStyle(Color.red)
                    .opacity(lightBlinkingOpacity)
                Circle() // border
                    .stroke(
                        lightBlinkingOpacity == 1 ?
                        Color.red :
                            Color.black.opacity(0.3),
                        lineWidth: 0.5
                    )
                Ellipse() // reflection
                    .foregroundStyle(Color.white)
                    .frame(width: 4, height: 2)
                    .offset(y: -2)
                    .opacity(reflectionOpacity)
                Circle().foregroundStyle(Gradient(colors: [.clear, .black]))
                    .opacity(lightBlinkingOpacity == 1 ? 0.05 : 0.2)
            }
            .frame(width: 8, height: 8)
        }
        .frame(width: 8, height: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).delay(0.4).repeatForever(autoreverses: true)) {
                lightBlinkingOpacity = 0.05
            }
        }
        .onDisappear {
            lightBlinkingOpacity = 1
        }
    }

    var reflectionOpacity: Double {
        if lightBlinkingOpacity == 1 {
            return 0.25
        } else {
            if colorScheme == .dark {
                return 0.3
            } else {
                return 0.6
            }
        }
    }
}

#Preview {
    BlinkingLight()
        .padding()
}
