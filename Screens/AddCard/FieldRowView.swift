import SwiftUI

struct FieldRowView: View {

    let field: FieldDefinition
    let type: CardType
    @Binding var value: String

    @Binding var selectedIntent: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 8) {
                Text(field.label.uppercased() + (field.kind == .picker ? " CHIP" : ""))
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1.5)

                if field.required {
                    Circle()
                        .fill(Color.freshLime)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            switch field.kind {

            case .picker:
                Menu {
                    ForEach(FieldCatalog.intents(for: type), id: \.self) { intent in
                        Button(intent) {
                            selectedIntent = intent
                            value = intent
                        }
                    }
                } label: {
                    HStack {
                        Text(value.isEmpty ? "Choose an intent" : value)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(value.isEmpty ? .white.opacity(0.3) : .white)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }

            default:
                TextField(field.placeholder, text: $value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.never)
                    .keyboardType(keyboardType(for: field.keyboard))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
        }
    }

    private func keyboardType(for k: FieldDefinition.KeyboardType) -> UIKeyboardType {
        switch k {
        case .normal: return .default
        case .email: return .emailAddress
        case .phone: return .phonePad
        case .url: return .URL
        }
    }
}
