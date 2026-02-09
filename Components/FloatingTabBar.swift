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

            HStack(spacing: 24) {
                // My Cards Tab
                TabButton(
                    icon: "rectangle.fill",
                    isSelected: selectedTab == .myCards,
                    activeColor: .freshLime
                ) {
                    selectedTab = .myCards
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }

                // Add Card Tab
                TabButton(
                    icon: "plus",
                    isSelected: selectedTab == .add,
                    activeColor: .softRose
                ) {
                    selectedTab = .add
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }

                // Inbox Tab
                TabButton(
                    icon: "person.2.fill",
                    isSelected: selectedTab == .inbox,
                    activeColor: .softRose
                ) {
                    selectedTab = .inbox
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color.charcoalGrey)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.stealthWhite, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.bottom, 24)
        }
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isSelected ? Color.charcoalGrey : Color.white.opacity(0.4))
                .frame(width: 54, height: 54)
                .background(isSelected ? activeColor : Color.clear)
                .clipShape(Circle())
                .accessibilityLabel(Text(isSelected ? "Selected tab" : "Tab"))
        }
    }
}

