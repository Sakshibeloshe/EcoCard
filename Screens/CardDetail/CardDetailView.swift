import SwiftUI

struct CardDetailView: View {
    let card: CardModel
    
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var noteText: String = ""
    @State private var isStarred: Bool = false
    
    init(card: CardModel) {
        self.card = card
        _noteText = State(initialValue: card.note)
        _isStarred = State(initialValue: card.isFavorite)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Card front preview at top
                    CardFrontView(card: card)
                        .padding(.top, 20)

                    // Action Buttons (Save Contact / Message)
                    HStack(spacing: 12) {
                        Button {
                            // save contact logic
                        } label: {
                            Text("SAVE CONTACT")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        
                        Button {
                            if let phone = card.phone, let url = URL(string: "sms:\(phone)") {
                                openURL(url)
                            }
                        } label: {
                            Text("MESSAGE")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.charcoalGrey.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Details Section
                    VStack(spacing: 16) {
                        detailItem(title: "RECEIVED AT", value: card.eventName ?? "Direct Transfer", icon: "location.fill")
                        
                        detailItem(title: "DATE", value: formattedDate(card.createdAt), icon: "calendar")
                        
                        bioItem()
                    }
                    .padding(.horizontal, 16)

                    // Delete Connection
                    Button(role: .destructive) {
                        store.deleteCard(card)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("DELETE CONNECTION")
                                .font(.system(size: 12, weight: .black))
                                .tracking(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                        .foregroundStyle(.red)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(card)
                    isStarred.toggle()
                } label: {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(isStarred ? .yellow : .white)
                        .padding(10)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func detailItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1.5)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.charcoalGrey.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private func bioItem() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.3))
                
                Text("BIO & NOTES")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1.5)
                
                Spacer()
            }
            
            Text(card.bio.isEmpty ? "No bio available for this contact." : card.bio)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.charcoalGrey.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

