//
//  SearchBar.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.25))

            TextField(placeholder, text: $text)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)

        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
}

