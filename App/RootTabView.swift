
import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Tab = .myCards

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
            .padding(.bottom, 90)

            FloatingTabBar(selectedTab: $selectedTab)
        }
    }
}

enum Tab {
    case myCards, add, inbox
}

