//
//  ShortcutSymbol.swift
//
//
//  Created by Adam Różyński on 22/02/2024.
//
#if os(macOS)

import SwiftUI

struct ShortcutSymbol: View {
    let symbol: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(symbol)
            .shortcutStyle()
            .foregroundColor(.primary)
            .frame(width: 22, height: 22)
            .visualEffect(.adaptive(.titlebar))
            .background {
                ZStack {
                    Group {
                        if colorScheme == .dark {
                            Color.black
                        } else {
                            Color.white
                        }
                    }
                    .opacity(colorScheme == .dark ? 0.2 : 0.6)
                    VStack {
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.9)
                            .frame(height: 2)
                            .blur(radius: 2)
                        Spacer()
                    }
                    VStack {
                        Spacer()
                        Color.black.opacity(colorScheme == .dark ? 0.7 : 0.1)
                            .frame(height: 1)
                            .blur(radius: 1)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 2)
    }
}

extension View {
    func shortcutStyle() -> some View {
        self
            .font(.system(size: 13))
            .fontWeight(.regular)
    }
}

#if DEBUG
#Preview {
    ShortcutSymbol(symbol: "⌘")
        .padding()
}
#Preview("dark mode") {
    ShortcutSymbol(symbol: "␛")
        .padding()
        .preferredColorScheme(.dark)
}
#endif

#endif
