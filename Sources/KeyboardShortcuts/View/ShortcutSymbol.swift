//
//  ShortcutSymbol.swift
//
//
//  Created by Adam Różyński on 22/02/2024.
//

import SwiftUI

struct ShortcutSymbol: View {
    let symbol: String
    @Environment(\.colorScheme) private var colorScheme

    static let backgroundLight = Color(red: 249/255, green: 248/255, blue: 250/55)
    static let backgroundDark = Color(red: 0.21, green: 0.19, blue: 0.23, opacity: 1.00)

    var body: some View {
        Text(symbol)
            .shortcutStyle()
            .foregroundColor(.primary)
            .frame(width: 22, height: 22)
            .modify {
                if colorScheme == .dark {
                    $0.background {
                        ZStack {
                            Self.backgroundDark
                            VStack {
                                Color.white.opacity(0.1)
                                    .frame(height: 3)
                                    .blur(radius: 3)
                                Spacer()
                            }
                            VStack {
                                Spacer()
                                Color.black.opacity(0.9)
                                    .frame(height: 2)
                                    .blur(radius: 2)
                            }
                        }
                    }
                } else {
                    $0.background {
                        ZStack {
                            Self.backgroundLight
                            VStack {
                                Color.white
                                    .frame(height: 4)
                                    .blur(radius: 2)
                                Spacer()
                            }
                            VStack {
                                Spacer()
                                Color.black.opacity(0.13)
                                    .frame(height: 1)
                                    .blur(radius: 2)
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 2)
    }
}

extension View {
    func shortcutStyle() -> some View {
        self
            .font(.system(size: 13))
            .fontWeight(.medium)

    }
}

#if DEBUG
#Preview {
    ShortcutSymbol(symbol: "⌘")
        .padding()
}
#endif
