import SwiftUI
import Combine

@MainActor
class ProfileStore: ObservableObject {
    static let shared = ProfileStore()
    
    @AppStorage("profile_fullName") var fullName: String = "Emily Parker"
    @AppStorage("profile_title") var title: String = "Product Designer"
    @AppStorage("profile_company") var company: String = "Studio Linear"
    @AppStorage("profile_bio") var bio: String = "Designer exploring the inters"
    @AppStorage("profile_email") var email: String = "emily@linear.studio"
    @AppStorage("profile_website") var website: String = "linear.studio"
    @AppStorage("profile_phone") var phone: String = ""
    @AppStorage("profile_pronouns") var pronouns: String = "she/her"
    @AppStorage("profile_photo") var photo: String = ""
    
    @AppStorage("profile_instagram") var instagram: String = "@emily.design"
    @AppStorage("profile_linkedIn") var linkedIn: String = "linkedin.com/in/emilyparker"
    @AppStorage("profile_github") var github: String = "github.com/emilyp"
    @AppStorage("profile_portfolio") var portfolio: String = "emilyparker.design"
    
    @AppStorage("settings_autoAccept") var autoAccept: Bool = true
    @AppStorage("settings_darkMode") var darkMode: String = "Default"
    
    private init() {}
}

