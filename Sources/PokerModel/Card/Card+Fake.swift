import Foundation

extension Card {
    public static func fake(
        rank: Rank = Rank.allCases.randomElement()!,
        suit: Suit = Suit.allCases.randomElement()!
    ) -> Card {
        .init(rank: rank, suit: suit)
    }
}

extension Deck {
    public static func fake() -> Deck {
        .init(cards: [
            Card(rank: .nine, suit: .heart), Card(rank: .four, suit: .spade),
            Card(rank: .ace, suit: .spade), Card(rank: .ace, suit: .diamond),
            Card(rank: .jack, suit: .heart), Card(rank: .king, suit: .heart),
            Card(rank: .three, suit: .heart), Card(rank: .two, suit: .heart),
            Card(rank: .eight, suit: .diamond), Card(rank: .nine, suit: .spade),
            Card(rank: .two, suit: .club), Card(rank: .ten, suit: .spade),
            Card(rank: .queen, suit: .heart), Card(rank: .jack, suit: .diamond),
            Card(rank: .king, suit: .spade), Card(rank: .six, suit: .club),
            Card(rank: .seven, suit: .heart), Card(rank: .ten, suit: .club),
            Card(rank: .three, suit: .club), Card(rank: .eight, suit: .spade),
            Card(rank: .six, suit: .spade), Card(rank: .five, suit: .diamond),
            Card(rank: .four, suit: .diamond), Card(rank: .queen, suit: .club),
            Card(rank: .four, suit: .heart), Card(rank: .seven, suit: .spade),
            Card(rank: .nine, suit: .club), Card(rank: .jack, suit: .club),
            Card(rank: .nine, suit: .diamond), Card(rank: .ace, suit: .heart),
            Card(rank: .three, suit: .diamond), Card(rank: .five, suit: .spade),
            Card(rank: .six, suit: .diamond), Card(rank: .eight, suit: .heart),
            Card(rank: .ace, suit: .club), Card(rank: .king, suit: .diamond),
            Card(rank: .three, suit: .spade), Card(rank: .six, suit: .heart),
            Card(rank: .ten, suit: .heart), Card(rank: .ten, suit: .diamond),
            Card(rank: .queen, suit: .spade), Card(rank: .five, suit: .club),
            Card(rank: .jack, suit: .spade), Card(rank: .seven, suit: .club),
            Card(rank: .two, suit: .spade), Card(rank: .four, suit: .club),
            Card(rank: .eight, suit: .club), Card(rank: .seven, suit: .diamond),
            Card(rank: .king, suit: .club), Card(rank: .queen, suit: .diamond),
            Card(rank: .five, suit: .heart), Card(rank: .two, suit: .diamond),
        ])
    }
}
