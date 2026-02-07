//
//  TemplateRow.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 07/02/26.
//
import SwiftUI

struct TemplateRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var color: Color = .gray // Default if not specified

    var body: some View {
        HStack(spacing: 18) {

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.15)) // Tinted background
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color) // Colored icon
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold)) // Bolder title
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 11, weight: .heavy)) // Smaller, heavier subtitle
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.4)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.15))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.04)) // Very dark background
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous)) // More rounded
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
