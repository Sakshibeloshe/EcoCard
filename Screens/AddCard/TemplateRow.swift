import SwiftUI

struct TemplateRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var color: Color = .gray
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 18) {

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.4)
            }

            Spacer()


            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.15))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
