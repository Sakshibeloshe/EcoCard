
import SwiftUI

struct FolderListView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        if !store.folders.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.folders) { folder in
                        Text(folder.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.deleteFolder(id: folder.id)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    Label("Delete Folder", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
    }
}
