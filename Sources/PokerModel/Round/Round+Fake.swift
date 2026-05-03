import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .init(),
        variant: Variant = .noLimitHoldEm,
        blinds: Blinds = .init(25, 50),
        players: [Player] = [
            .fake(id: "1", name: "Al", chipCount: 1500),
            .fake(id: "2", name: "Bob", chipCount: 1500),
            .fake(id: "3", name: "Cat", chipCount: 1500),
            .fake(id: "4", name: "Dave", chipCount: 1500),
        ],
        cookedDeck: Deck? = .fake()
    ) throws -> Round {
        try .init(
            id: id, started: started, variant: variant,
            blinds: blinds, players: players, cookedDeck: cookedDeck
        )
    }

    public static func randomizedFake(
        variant: Variant = .noLimitHoldEm,
        blinds: Blinds = .init(25, 50),
        playerCount: Int = 4,
        difficulty: AIEngine.Difficulty = .medium
    ) throws -> Round {
        let players: [Player] = (1...playerCount).map {
            .fake(id: "\($0)", name: "P\($0)", chipCount: 1500)
        }
        var round: Round = try .init(variant: variant, blinds: blinds, players: players)
        let moveCount: Int = .random(in: 1...25)
        for _ in 0..<moveCount {
            round = AIEngine.makeMove(in: round, difficulty: difficulty, autoAdvance: false)
            if round.isComplete { break }
        }
        return round
    }
}

extension HoldEmState {
    public static func fake() -> HoldEmState {
        .init(holeCards: [:], board: [], revealedBoardCount: 0)
    }
}

extension OmahaState {
    public static func fake() -> OmahaState {
        .init(holeCards: [:], board: [], revealedBoardCount: 0)
    }
}

extension PineappleState {
    public static func fake() -> PineappleState {
        .init(holeCards: [:], board: [])
    }
}

extension StudState {
    public static func fake() -> StudState {
        .init(playerCards: [:], deck: [])
    }
}

extension DrawState {
    public static func fake() -> DrawState {
        .init(playerCards: [:], deck: [])
    }
}

extension PokerHand {
    public static func fake() -> PokerHand {
        try! .init(cards: [
            Card(rank: .ace, suit: .spade), Card(rank: .king, suit: .spade),
            Card(rank: .queen, suit: .spade), Card(rank: .jack, suit: .spade),
            Card(rank: .ten, suit: .spade),
        ])
    }
}

extension WinningHand {
    public static func fake() -> WinningHand {
        .init(playerID: UUID().uuidString, pokerHand: .fake())
    }
}

extension Pot {
    public static func fake() -> Pot {
        .init(amount: 100, playerIds: ["1", "2"])
    }
}

extension PotResult {
    public static func fake() -> PotResult {
        .init(pot: .fake(), highWinners: [.fake()])
    }
}
