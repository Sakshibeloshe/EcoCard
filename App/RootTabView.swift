
import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Tab = .myCards

    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .myCards:
                    NavigationStack {
                        MyCardsView()
                    }
                case .add:
                    NavigationStack {
                        AddCardView()
                    }
                case .inbox:
                    NavigationStack {
                        InboxView()
                    }
                }
            }
            // Removed padding to allow content to flow behind floating UI

            FloatingTabBar(selectedTab: $selectedTab)
        }
    }
}

enum Tab {
    case myCards, add, inbox
}

