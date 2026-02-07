//
//  CardPreviewView.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct CardPreviewView: View {
    let name: String
    let subtitle: String
    let org: String
    let email: String
    let website: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 18) {

                // Top row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(name)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.88))

                        Text(subtitle.uppercased())
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.black.opacity(0.45))
                            .tracking(1.2)
                    }

                    Spacer()

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.12))
                        .frame(width: 54, height: 54)
                }

                Spacer(minLength: 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text(org.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.black.opacity(0.55))
                        .tracking(1.4)

                    Text(email)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.65))

                    Text(website)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.65))
                }

                Spacer(minLength: 8)

                HStack {
                    Spacer()
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.45))
                }
            }
            .padding(28) // IMPORTANT
        }
        .frame(height: 290) // IMPORTANT
        .padding(.horizontal, 16)
    }
}
