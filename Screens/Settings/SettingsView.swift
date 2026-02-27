import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profile = ProfileStore.shared
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidianBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Profile Preview
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 120, height: 120)

                                    if !profile.photo.isEmpty,
                                       let data = Data(base64Encoded: profile.photo.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white.opacity(0.5))
                                    }

                                    // Add/Edit Badge
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "pencil.circle.fill")
                                                .symbolRenderingMode(.multicolor)
                                                .font(.system(size: 32))
                                                .background(Circle().fill(Color.obsidianBlack))
                                        }
                                    }
                                }

                                VStack(spacing: 4) {
                                    Text(profile.fullName)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)

                                    Text(profile.title.uppercased())
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.4))
                                        .tracking(2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    let resized = img.resizedIfNeeded(maxDimension: 512)
                                    if let jpegData = resized.jpegData(compressionQuality: 0.7) {
                                        profile.photo = jpegData.base64EncodedString()
                                    }
                                }
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 24) {
                            // GLOBAL AUTOFILL
                            SettingsSection(title: "GLOBAL AUTOFILL") {
                                SettingsRow(icon: "person.fill", label: "FULL NAME", value: $profile.fullName)
                                SettingsRow(icon: "briefcase.fill", label: "TITLE", value: $profile.title)
                                SettingsRow(icon: "building.2.fill", label: "COMPANY", value: $profile.company)
                                SettingsRow(icon: "info.circle.fill", label: "BIO", value: $profile.bio)
                                SettingsRow(icon: "envelope.fill", label: "EMAIL", value: $profile.email)
                                SettingsRow(icon: "link", label: "WEBSITE", value: $profile.website)
                                SettingsRow(icon: "phone.fill", label: "PHONE", value: $profile.phone, placeholder: "Enter phone")
                                SettingsRow(icon: "at", label: "PRONOUNS", value: $profile.pronouns)
                            }

                            // SOCIALS
                            SettingsSection(title: "SOCIALS") {
                                SettingsRow(icon: "camera.fill", label: "INSTAGRAM", value: $profile.instagram)
                                SettingsRow(icon: "link", label: "LINKEDIN", value: $profile.linkedIn)
                                SettingsRow(icon: "chevron.left.slash.chevron.right", label: "GITHUB", value: $profile.github)
                                SettingsRow(icon: "sparkles", label: "PORTFOLIO", value: $profile.portfolio)
                            }

                            // TRANSFERS
                            SettingsSection(title: "TRANSFERS") {
                                ToggleRow(icon: "bolt.fill", label: "Auto-Accept", description: "INSTANTLY SAVE SHARED CARDS.", isOn: $profile.autoAccept)
                            }

                            // SYSTEM
                            SettingsSection(title: "SYSTEM") {
                                NavigationRow(icon: "moon.fill", label: "Dark Mode", value: profile.darkMode)
                                NavigationRow(icon: "shield.fill", label: "Privacy & Security", value: "")
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Button {
                            // Reset logic
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.to.line")
                                Text("RESET PROFILE DATA")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.05))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.red.opacity(0.1), lineWidth: 1)
                                    )

                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("SETTINGS & PROFILE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.obsidianBlack, for: .navigationBar)
        }
    }
}

// MARK: - Subviews

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(2)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let label: String
    @Binding var value: String
    var placeholder: String = ""
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                
                TextField(placeholder, text: $value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        Divider()
            .background(Color.white.opacity(0.05))
            .padding(.leading, 72)
    }
}

struct ToggleRow: View {
    let icon: String
    let label: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                
                Text(label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.2))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .skyBlue))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

struct NavigationRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }
}
