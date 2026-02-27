import SwiftUI

struct FolderPickerSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let card: CardModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidianBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {

                        // Remove from folder option — only if already in one
                        if card.folderId != nil {
                            Button {
                                store.removeCardFromFolder(cardId: card.id)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "folder.badge.minus")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.orange)
                                        .frame(width: 44, height: 44)
                                        .background(Color.orange.opacity(0.1))
                                        .clipShape(Circle())

                                    Text("Remove from Folder")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.orange)

                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.orange.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // No folder
                        folderRow(
                            icon: "xmark.circle",
                            name: "No Folder",
                            isSelected: card.folderId == nil,
                            color: .white.opacity(0.35)
                        ) {
                            store.assignFolder(cardId: card.id, folderId: nil)
                            dismiss()
                        }

                        // Existing folders
                        ForEach(store.folders) { folder in
                            let count = store.inboxCards.filter { $0.folderId == folder.id }.count
                            folderRow(
                                icon: "folder.fill",
                                name: folder.name,
                                badge: count > 0 ? "\(count)" : nil,
                                isSelected: card.folderId == folder.id,
                                color: .white.opacity(0.8)
                            ) {
                                store.assignFolder(cardId: card.id, folderId: folder.id)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func folderRow(icon: String, name: String, badge: String? = nil, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        // Break conditional expressions into locals so the compiler can type-check each one.
        let iconFg: Color    = isSelected ? .black : color
        let iconBg: Color    = isSelected ? Color.white : Color.white.opacity(0.08)
        let nameFg: Color    = isSelected ? .white : color
        let rowBg: Color     = isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.04)
        let rowBorder: Color = isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05)

        return Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconFg)
                    .frame(width: 40, height: 40)
                    .background(iconBg)
                    .clipShape(Circle())

                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(nameFg)

                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.freshLime)
                }
            }
            .padding(14)
            .background(rowBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(rowBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
