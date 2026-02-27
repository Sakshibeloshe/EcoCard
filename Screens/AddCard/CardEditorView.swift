import SwiftUI
import CoreData
import PhotosUI

struct CardEditorView: View {

    let type: CardType

    // Holds values typed by user
    @State private var values: [String: String] = [:]
    @StateObject private var profile = ProfileStore.shared

    // Intent picker
    @State private var selectedIntent: String = ""

    // Photo
    @State private var pickedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoWasChanged: Bool = false
    
    // Theme selection
    @State private var selectedTheme: CardTheme = .pink
    
    // Preview sheet
    @State private var showPreview = false
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    init(type: CardType) {
        self.type = type
        
        let profile = ProfileStore.shared
        var initialValues: [String: String] = [:]
        
        // General fields
        initialValues["fullName"] = profile.fullName
        initialValues["title"] = profile.title
        initialValues["company"] = profile.company
        initialValues["bio"] = profile.bio
        initialValues["email"] = profile.email
        initialValues["website"] = profile.website
        initialValues["phone"] = profile.phone
        initialValues["pronouns"] = profile.pronouns
        
        // Socials & New Fields
        initialValues["instagram"] = profile.instagram
        initialValues["linkedin"] = profile.linkedIn
        initialValues["github"] = profile.github
        initialValues["portfolio"] = profile.portfolio
        
        // Map any other available profile info to keys used in FieldCatalog
        initialValues["nickname"] = profile.fullName
        initialValues["displayName"] = profile.fullName
        
        _values = State(initialValue: initialValues)
        _selectedIntent = State(initialValue: FieldCatalog.intents(for: type).first ?? "")
        
        // Pre-fill photo from profile
        if !profile.photo.isEmpty,
           let data = Data(base64Encoded: profile.photo.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
           let img = UIImage(data: data) {
            _pickedImage = State(initialValue: img)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Live Card Preview
                    CardView(card: previewCard)
                        .frame(height: 210)
                        .padding(.top, 10)

                    // Theme Picker Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE THEME")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        ThemeColorPicker(selectedTheme: $selectedTheme)
                    }

                    // Photo Picker Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PHOTO")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.5)

                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 14) {
                                // Thumbnail or placeholder
                                ZStack {
                                    if let img = pickedImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.08))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 22))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(pickedImage == nil ? "Add Profile Photo" : "Change Photo")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("FROM YOUR PHOTO LIBRARY")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.35))
                                        .tracking(1.2)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.charcoalGrey.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }

                    // Form Fields
                    VStack(spacing: 0) {
                        ForEach(FieldCatalog.fields(for: type)) { field in
                            FieldRowView(
                                field: field,
                                type: type,
                                value: Binding(
                                    get: { values[field.key, default: ""] },
                                    set: { values[field.key] = $0 }
                                ),
                                selectedIntent: $selectedIntent
                            )
                            
                            if field.key != FieldCatalog.fields(for: type).last?.key {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(Color.charcoalGrey.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    // Preview Button
                    Button {
                        showPreview = true
                    } label: {
                        Text("CONTINUE TO PREVIEW")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.black)
                            .tracking(2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
            }
        }
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: selectedPhotoItem) { newItem in
            Task { @MainActor in
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    // Downscale to protect payload size during Multipeer send.
                    pickedImage = img.resizedIfNeeded(maxDimension: 512)
                    photoWasChanged = true
                }
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            CardEditorPreview(
                card: previewCard,
                onSave: { saveCard() },
                onEdit: { showPreview = false }
            )
        }
    }
    
    // Generate preview card from current values
    private var previewCard: CardModel {
        let fullName = values["fullName"] ?? values["nickname"] ?? "Your Name"
        let company = values["company"] ?? values["eventBadge"] ?? ""
        let intent = selectedIntent.isEmpty ? nil : selectedIntent
        
        let photoBase64: String? = {
            if let img = pickedImage, let data = img.jpegData(compressionQuality: 0.7) {
                return data.base64EncodedString()
            }
            return nil
        }()

        return CardModel(
            type: type,
            theme: selectedTheme,
            fullName: fullName,
            title: values["title"] ?? "",
            company: company,
            bio: values["bio"] ?? "",
            email: values["email"],
            website: values["website"],
            phone: values["phone"],
            pronouns: values["pronouns"],
            photo: photoBase64,
            locationCity: values["locationCity"],
            officeLocation: values["officeLocation"],
            linkedin: values["linkedin"],
            instagram: values["instagram"],
            github: values["github"],
            snapchat: values["snapchat"],
            spotify: values["spotify"],
            whatsapp: values["whatsapp"],
            eventBadge: values["eventBadge"],
            skillsTags: values["skillsTags"],
            emojiTags: values["emojiTags"],
            nickname: values["nickname"],
            intent: intent
        )
    }

    private func saveCard() {
        do {
            let repo = CardRepository(context: context)
            
            // Determine sync flags
            let profile = ProfileStore.shared
            let usesProfileName = (values["fullName"] ?? profile.fullName) == profile.fullName
            let usesProfileTitle = (values["title"] ?? profile.title) == profile.title
            
            // For company, CardRepository maps it from values["company"] ?? values["eventName"]
            // We'll just check if values["company"] matches profile.company
            let usesProfileCompany = (values["company"] ?? profile.company) == profile.company
            
            let usesProfilePhoto = !photoWasChanged
            
            try repo.createCard(
                type: type,
                values: values,
                photo: pickedImage,
                theme: selectedTheme,
                usesProfileName: usesProfileName,
                usesProfileTitle: usesProfileTitle,
                usesProfileCompany: usesProfileCompany,
                usesProfilePhoto: usesProfilePhoto
            )
            print("Successfully saved card: \(type.title)")
            dismiss()
        } catch {
            print("Failed saving:", error.localizedDescription)
            // Ideally show an alert here
        }
    }
}

// MARK: - Preview Sheet
struct CardEditorPreview: View {
    @Environment(\.dismiss) var dismiss
    let card: CardModel
    let onSave: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Card Preview
                CardView(card: card)
                    .frame(height: 210)
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Save Card Button
                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        Text("SAVE CARD")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    HStack(spacing: 16) {
                        // Cancel Button
                        Button {
                            dismiss()
                        } label: {
                            Text("CANCEL")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        // Make Edits Button
                        Button {
                            dismiss()
                            onEdit()
                        } label: {
                            Text("MAKE EDITS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}
