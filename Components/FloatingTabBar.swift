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

            HStack(spacing: 12) {
                // My Cards Tab
                TabButton(
                    icon: "rectangle.fill",
                    label: "My Cards",
                    isSelected: selectedTab == .myCards,
                    activeColor: .freshLime
                ) {
                    selectedTab = .myCards
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }

                // Add Card Tab
                TabButton(
                    icon: "plus",
                    label: "Add Card",
                    isSelected: selectedTab == .add,
                    activeColor: .softRose
                ) {
                    selectedTab = .add
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }

                // Inbox Tab
                TabButton(
                    icon: "person.2.fill",
                    label: "Inbox",
                    isSelected: selectedTab == .inbox,
                    activeColor: .skyBlue
                ) {
                    selectedTab = .inbox
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .background(Color.charcoalGrey.opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
            .padding(.bottom, 10) // Lessen constraint from bottom
        }
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(isSelected ? Color.charcoalGrey : Color.white.opacity(0.4))
            .frame(width: 80, height: 58)
            .background(isSelected ? activeColor : Color.clear)
            .clipShape(Capsule())
            .accessibilityLabel(Text(isSelected ? "Selected \(label) tab" : "\(label) tab"))
        }
    }
}

