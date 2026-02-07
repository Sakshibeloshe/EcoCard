import SwiftUI

struct CardView: View {
    let card: CardModel

    var body: some View {
        CardFrontView(card: card)
    }
}
