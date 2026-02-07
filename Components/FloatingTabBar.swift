//
//  FloatingTabBar.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                HStack(spacing: 18) {

                    Button {
                        selectedTab = .myCards
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selectedTab == .myCards ? .black : .white.opacity(0.35))
                            .frame(width: 46, height: 46)
                            .background(selectedTab == .myCards ? Color.white.opacity(0.9) : Color.clear)
                            .clipShape(Circle())
                    }

                    Button {
                        selectedTab = .add
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.black)
                            .frame(width: 62, height: 62)
                            .background(Color(red: 1.0, green: 0.78, blue: 0.84))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.35), radius: 18, y: 12)
                    }

                    Button {
                        selectedTab = .inbox
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selectedTab == .inbox ? .black : .white.opacity(0.35))
                            .frame(width: 46, height: 46)
                            .background(selectedTab == .inbox ? Color.white.opacity(0.9) : Color.clear)
                            .clipShape(Circle())
                    }

                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.bottom, 24)

                Spacer()
            }
        }
    }
}

