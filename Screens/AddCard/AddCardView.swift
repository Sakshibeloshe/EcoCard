import SwiftUI

struct AddCardView: View {
    @EnvironmentObject var eventManager: EventModeManager
    @State private var showEventDialog = false
    @State private var animateItems = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                TopNavBar()
                    .padding(.horizontal, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Create Card")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 10)

                        Text("Auto-filling details from your profile")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.35))
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 10)

                        VStack(spacing: 16) {
                            NavigationLink(value: CardType.personal) {
                                TemplateRow(icon: "creditcard.fill", title: "Personal Card", subtitle: "SOCIAL & BASIC INFO", color: Color(red: 1.0, green: 0.70, blue: 0.75))
                            }
                            .opacity(animateItems ? 1 : 0)
                            .scaleEffect(animateItems ? 1 : 0.8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateItems)
                            
                            NavigationLink(value: CardType.business) {
                                TemplateRow(icon: "briefcase.fill", title: "Business Card", subtitle: "CORPORATE & PROFESSIONAL", color: Color(red: 0.95, green: 0.90, blue: 0.60))
                            }
                            .opacity(animateItems ? 1 : 0)
                            .scaleEffect(animateItems ? 1 : 0.8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateItems)
                            
                            NavigationLink(value: CardType.social) {
                                TemplateRow(icon: "sparkles", title: "Social Profile", subtitle: "EXPRESSIVE & BOLD", color: Color(red: 0.60, green: 0.85, blue: 0.95))
                            }
                            .opacity(animateItems ? 1 : 0)
                            .scaleEffect(animateItems ? 1 : 0.8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animateItems)
                            
                            NavigationLink(value: CardType.event) {
                                TemplateRow(icon: "ticket.fill", title: "Event Badge", subtitle: "CONFERENCES & SKILLS", color: Color(red: 0.80, green: 0.70, blue: 0.95))
                            }
                            .opacity(animateItems ? 1 : 0)
                            .scaleEffect(animateItems ? 1 : 0.8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateItems)
                            
                            NavigationLink(value: CardType.blank) {
                                TemplateRow(icon: "plus", title: "Custom Blank", subtitle: "BUILD FROM SCRATCH", color: Color.gray)
                            }
                            .opacity(animateItems ? 1 : 0)
                            .scaleEffect(animateItems ? 1 : 0.8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateItems)
                        }
                        .padding(.top, 18)
                        
                        Spacer(minLength: 120) // For tab bar
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEventDialog) {
            EventModeSheet()
                .environmentObject(eventManager)
        }
        .navigationDestination(for: CardType.self) { type in
            CardEditorView(type: type)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateItems = true
            }
        }
    }
}
