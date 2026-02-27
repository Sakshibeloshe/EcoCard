import SwiftUI

struct FolderDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let folder: FolderModel
    @State private var showDeleteFolderAlert = false

    var cardsInFolder: [CardModel] {
        store.inboxCards.filter { $0.folderId == folder.id }
    }

    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Back Button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("BACK")
                                .font(.system(size: 12, weight: .black))
                                .tracking(1.2)
                        }
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(folder.name)
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)

                            Text("\(cardsInFolder.count) card\(cardsInFolder.count == 1 ? "" : "s")")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.35))
                        }

                        Spacer()

                        // Delete folder button
                        Button {
                            showDeleteFolderAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if cardsInFolder.isEmpty {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 28) {
                            ForEach(cardsInFolder) { card in
                                VStack(alignment: .leading, spacing: 12) {
                                    CardFrontView(card: card)
                                        .buttonStyle(CardPressButtonStyle())
                                        // Swipe to remove from folder
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button {
                                                withAnimation(.spring()) {
                                                    store.removeCardFromFolder(cardId: card.id)
                                                }
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            } label: {
                                                Label("Remove", systemImage: "folder.badge.minus")
                                            }
                                            .tint(.orange)
                                        }

                                    // Card info row
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(card.fullName)
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                            if !card.title.isEmpty {
                                                Text(card.title.uppercased())
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(.white.opacity(0.4))
                                                    .tracking(0.8)
                                            }
                                        }
                                        Spacer()
                                        // Remove from folder
                                        Button {
                                            withAnimation(.spring()) {
                                                store.removeCardFromFolder(cardId: card.id)
                                            }
                                        } label: {
                                            Image(systemName: "folder.badge.minus")
                                                .font(.system(size: 15))
                                                .foregroundStyle(.white.opacity(0.25))
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Delete \"\(folder.name)\"?", isPresented: $showDeleteFolderAlert) {
            Button("Delete", role: .destructive) {
                store.deleteFolder(id: folder.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Cards in this folder won't be deleted — just unorganised.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 80, height: 80)
                Image(systemName: "folder")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
            }
            Text("No cards yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Text("Add cards to this folder from the Inbox")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
