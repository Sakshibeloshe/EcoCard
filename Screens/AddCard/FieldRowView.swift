import SwiftUI

struct FieldRowView: View {

    let field: FieldDefinition
    @Binding var value: String

    @Binding var selectedIntent: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 8) {
                Text(field.label)
                    .font(.system(size: 14, weight: .semibold))

                if field.required {
                    Text("Required")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            switch field.kind {

            case .picker:
                Menu {
                    ForEach(FieldCatalog.intents, id: \.self) { intent in
                        Button(intent) {
                            selectedIntent = intent
                            value = intent
                        }
                    }
                } label: {
                    HStack {
                        Text(value.isEmpty ? "Choose an intent" : value)
                            .foregroundStyle(value.isEmpty ? .secondary : .primary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

            default:
                TextField(field.placeholder, text: $value)
                    .textInputAutocapitalization(.never)
                    .keyboardType(keyboardType(for: field.keyboard))
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
