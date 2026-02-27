import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            ZStack {
                if store.activeTab == .myCards {
                    NavigationStack { MyCardsView() }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                } else if store.activeTab == .add {
                    NavigationStack { AddCardView() }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                } else if store.activeTab == .inbox {
                    InboxView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: store.activeTab)

            FloatingTabBar(selectedTab: $store.activeTab)
        }
    }
}

enum Tab {
    case myCards, add, inbox
}
