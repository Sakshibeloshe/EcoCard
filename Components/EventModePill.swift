//
//  EventModePill.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 07/02/26.
//
import SwiftUI

struct EventModePill: View {
    let isLive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .bold))

            Text(isLive ? "EVENT LIVE" : "EVENT MODE")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(isLive ? .black : .white.opacity(0.85))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isLive ? Color(red: 1.0, green: 0.78, blue: 0.84) : Color.white.opacity(0.10))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
