//
//  AddCardView.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct AddCardView: View {
    @EnvironmentObject var eventManager: EventModeManager
    @State private var showEventDialog = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {

                    TopNavBar(eventManager: eventManager, showEventSheet: $showEventDialog)

                    Text("Create Card")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Select a template type")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))

                    VStack(spacing: 16) {
                        NavigationLink(value: CardType.personal) {
                            TemplateRow(icon: "creditcard.fill", title: "Personal Card", subtitle: "SOCIAL & BASIC INFO", color: Color(red: 1.0, green: 0.70, blue: 0.75))
                        }
                        
                        NavigationLink(value: CardType.business) {
                            TemplateRow(icon: "briefcase.fill", title: "Business Card", subtitle: "CORPORATE & PROFESSIONAL", color: Color(red: 0.95, green: 0.90, blue: 0.60))
                        }
                        
                        NavigationLink(value: CardType.social) {
                            TemplateRow(icon: "sparkles", title: "Social Profile", subtitle: "EXPRESSIVE & BOLD", color: Color(red: 0.60, green: 0.85, blue: 0.95))
                        }
                        
                        NavigationLink(value: CardType.event) {
                            TemplateRow(icon: "ticket.fill", title: "Event Badge", subtitle: "CONFERENCES & SKILLS", color: Color(red: 0.80, green: 0.70, blue: 0.95))
                        }
                        
                        NavigationLink(value: CardType.blank) {
                            TemplateRow(icon: "plus", title: "Custom Blank", subtitle: "BUILD FROM SCRATCH", color: Color.gray)
                        }
                    }
                    .padding(.top, 18)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEventDialog) {
                EventModeSheet()
                    .environmentObject(eventManager)
            }
            .navigationDestination(for: CardType.self) { type in
                CardEditorView(type: type)
            }
        }
    }
}
