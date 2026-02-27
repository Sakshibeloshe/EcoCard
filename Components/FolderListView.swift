import SwiftUI

struct FolderListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showCreateFolder = false
    @State private var newFolderName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.folders) { folder in
                    NavigationLink(destination: FolderDetailView(folder: folder)) {
                        folderPill(folder: folder)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            store.deleteFolder(id: folder.id)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }

                // Create folder button
                Button {
                    newFolderName = ""
                    showCreateFolder = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .black))
                        Text("New Folder")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
        .alert("New Folder", isPresented: $showCreateFolder) {
            TextField("Folder name", text: $newFolderName)
                .autocorrectionDisabled()
            Button("Create") {
                store.createFolder(name: newFolderName)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Give this folder a name")
        }
    }

    private func folderPill(folder: FolderModel) -> some View {
        let count = store.inboxCards.filter { $0.folderId == folder.id }.count

        return HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))

            Text(folder.name)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

