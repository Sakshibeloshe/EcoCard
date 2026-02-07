//
//  FilterPills.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct FilterPills: View {
    let items: [String]
    @Binding var selected: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Button {
                        selected = item
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(item.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(selected == item ? .black : .white.opacity(0.35))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                selected == item
                                ? Color.white
                                : Color.white.opacity(0.06)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

