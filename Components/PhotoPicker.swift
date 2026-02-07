import SwiftUI
import PhotosUI

struct PhotoPicker: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .frame(width: 90, height: 90)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("Add Photo")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 1.5)
                    )
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }
}
