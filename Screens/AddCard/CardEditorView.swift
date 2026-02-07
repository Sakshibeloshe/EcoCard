import SwiftUI
import CoreData
import PhotosUI

struct CardEditorView: View {

    let type: CardType

    // Holds values typed by user
    @State private var values: [String: String] = [:]

    // Intent picker
    @State private var selectedIntent: String = FieldCatalog.intents.first ?? ""

    // Photo
    @State private var pickedImage: UIImage?
    
    // Theme selection
    @State private var selectedTheme: CardTheme = .pink
    
    // Preview sheet
    @State private var showPreview = false
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

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

                    // Form Fields
                    VStack(spacing: 14) {
                        ForEach(FieldCatalog.fields(for: type)) { field in
                            FieldRowView(
                                field: field,
                                value: Binding(
                                    get: { values[field.key, default: ""] },
                                    set: { values[field.key] = $0 }
                                ),
                                selectedIntent: $selectedIntent
                            )
                        }
                    }

                    // Preview Button
                    Button {
                        showPreview = true
                    } label: {
                        Text("PREVIEW CARD")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        CardModel(
            type: type,
            theme: selectedTheme,
            fullName: values["fullName"] ?? "Your Name",
            title: values["title"] ?? "",
            company: values["company"] ?? "",
            bio: values["bio"] ?? "",
            email: values["email"],
            website: values["website"],
            phone: values["phone"],
            pronouns: values["pronouns"] ?? "",
            instagram: values["instagram"],
            linkedIn: values["linkedin"],
            github: values["github"],
            portfolio: values["portfolio"],
            intent: selectedIntent.isEmpty ? nil : selectedIntent
        )
    }

    private func saveCard() {
        do {
            let repo = CardRepository(context: context)
            try repo.createCard(type: type, values: values, photo: pickedImage, theme: selectedTheme)
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
