//
//  CardTypeTile.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct CardTypeTile: View {
    let type: CardType

    var body: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(typeColor.opacity(0.95))
                .frame(width: 86, height: 86)
                .overlay(
                    Text(type.emoji)
                        .font(.system(size: 36))
                )

            Text(type.rawValue.uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var typeColor: Color {
        switch type {
        case .personal: return .pink
        case .business: return .green
        case .social: return .cyan
        case .event: return .purple
        case .blank: return .orange
        }
    }
}

