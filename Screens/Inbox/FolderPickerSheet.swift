//
//  FolderPickerSheet.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct FolderPickerSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let card: CardModel

    var body: some View {
        NavigationStack {
            List {
                Button("No Folder") {
                    store.assignFolder(cardId: card.id, folderId: nil)
                    dismiss()
                }

                ForEach(store.folders) { folder in
                    Button(folder.name) {
                        store.assignFolder(cardId: card.id, folderId: folder.id)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add to Folder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

