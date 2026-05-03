import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        variant: Variant,
        blinds: Blinds,
        players: [Player],
        cookedDeck: Deck? = nil
    ) throws {
        guard players.count >= variant.minPlayers else {
            throw PokerError.insufficientPlayers
        }
        guard players.count <= variant.maxPlayers else {
            throw PokerError.tooManyPlayers
        }

        self.id = id
        self.started = started
        self.variant = variant
        self.blinds = blinds
        self.players = players.map { RoundPlayer(player: $0) }

        var deck: Deck = cookedDeck ?? .init()
        if cookedDeck == nil { deck.shuffle() }

        var cardsMap: [CardID: Card] = [:]

        switch variant {
        case .noLimitHoldEm, .limitHoldEm:
            let holdEmState: HoldEmState = Self.dealHoldEm(
                players: players, holeCardCount: 2, deck: &deck, cardsMap: &cardsMap
            )
            self.variantRound = variant == .noLimitHoldEm
                ? .noLimitHoldEm(holdEmState)
                : .limitHoldEm(holdEmState)
            self.state = .waitingForSmallBlind
            self.street = .first

        case .noLimitOmaha, .potLimitOmaha:
            let omahaState: OmahaState = Self.dealOmaha(
                players: players, deck: &deck, cardsMap: &cardsMap
            )
            self.variantRound = variant == .noLimitOmaha
                ? .noLimitOmaha(omahaState)
                : .potLimitOmaha(omahaState)
            self.state = .waitingForSmallBlind
            self.street = .first

        case .pineapple:
            let pineState: PineappleState = Self.dealPineapple(
                players: players, deck: &deck, cardsMap: &cardsMap
            )
            self.variantRound = .pineapple(pineState)
            self.state = .waitingForSmallBlind
            self.street = .first

        case .fiveCardDraw:
            let drawState: DrawState = Self.dealDraw(
                players: players, deck: &deck, cardsMap: &cardsMap
            )
            self.variantRound = .fiveCardDraw(drawState)
            self.state = .waitingForSmallBlind
            self.street = .first

        case .sevenCardStud, .razz, .studHighLow:
            let studState: StudState = Self.dealStud(
                players: players, deck: &deck, cardsMap: &cardsMap
            )
            self.variantRound = switch variant {
            case .razz: .razz(studState)
            case .studHighLow: .studHighLow(studState)
            default: .sevenCardStud(studState)
            }
            if blinds.ante > .zero {
                self.state = .waitingForAnte(playerIndex: 0)
            } else {
                let bringInIndex: Int = Self.findBringInPlayer(
                    studState: studState, players: players, variant: variant,
                    cardsMap: cardsMap
                )
                self.state = .waitingForBringIn(playerIndex: bringInIndex)
            }
            self.street = .first
        }

        self.cardsMap = cardsMap
    }

    // MARK: - Dealing Helpers

    private static func dealHoldEm(
        players: [Player], holeCardCount: Int, deck: inout Deck,
        cardsMap: inout [CardID: Card]
    ) -> HoldEmState {
        var holeCards: [PlayerID: [CardID]] = [:]
        for player in players {
            let dealt: [Card] = deck.deal(holeCardCount)
            for c in dealt { cardsMap[c.id] = c }
            holeCards[player.id] = dealt.map(\.id)
        }
        let boardCards: [Card] = deck.deal(5)
        for c in boardCards { cardsMap[c.id] = c }
        return .init(holeCards: holeCards, board: boardCards.map(\.id))
    }

    private static func dealOmaha(
        players: [Player], deck: inout Deck, cardsMap: inout [CardID: Card]
    ) -> OmahaState {
        var holeCards: [PlayerID: [CardID]] = [:]
        for player in players {
            let dealt: [Card] = deck.deal(4)
            for c in dealt { cardsMap[c.id] = c }
            holeCards[player.id] = dealt.map(\.id)
        }
        let boardCards: [Card] = deck.deal(5)
        for c in boardCards { cardsMap[c.id] = c }
        return .init(holeCards: holeCards, board: boardCards.map(\.id))
    }

    private static func dealPineapple(
        players: [Player], deck: inout Deck, cardsMap: inout [CardID: Card]
    ) -> PineappleState {
        var holeCards: [PlayerID: [CardID]] = [:]
        for player in players {
            let dealt: [Card] = deck.deal(3)
            for c in dealt { cardsMap[c.id] = c }
            holeCards[player.id] = dealt.map(\.id)
        }
        let boardCards: [Card] = deck.deal(5)
        for c in boardCards { cardsMap[c.id] = c }
        return .init(holeCards: holeCards, board: boardCards.map(\.id))
    }

    private static func dealDraw(
        players: [Player], deck: inout Deck, cardsMap: inout [CardID: Card]
    ) -> DrawState {
        var playerCards: [PlayerID: [CardID]] = [:]
        for player in players {
            let dealt: [Card] = deck.deal(5)
            for c in dealt { cardsMap[c.id] = c }
            playerCards[player.id] = dealt.map(\.id)
        }
        let remainingIDs: [CardID] = deck.cards.map { c in
            cardsMap[c.id] = c
            return c.id
        }
        return .init(playerCards: playerCards, deck: remainingIDs)
    }

    private static func dealStud(
        players: [Player], deck: inout Deck, cardsMap: inout [CardID: Card]
    ) -> StudState {
        var playerCards: [PlayerID: StudPlayerCards] = [:]
        for player in players {
            let downCards: [Card] = deck.deal(2)
            let upCards: [Card] = deck.deal(1)
            for c in downCards + upCards { cardsMap[c.id] = c }
            playerCards[player.id] = .init(
                downCards: downCards.map(\.id), upCards: upCards.map(\.id)
            )
        }
        let remainingIDs: [CardID] = deck.cards.map { c in
            cardsMap[c.id] = c
            return c.id
        }
        return .init(playerCards: playerCards, deck: remainingIDs)
    }

    internal static func findBringInPlayer(
        studState: StudState, players: [Player], variant: Variant,
        cardsMap: [CardID: Card]
    ) -> Int {
        var lowestIndex: Int = 0
        var lowestCard: Card?
        for (index, player) in players.enumerated() {
            guard let cards: StudPlayerCards = studState.playerCards[player.id],
                  let upCardID: CardID = cards.upCards.first,
                  let upCard: Card = cardsMap[upCardID] else { continue }
            if let current: Card = lowestCard {
                let isLower: Bool
                if variant == .razz {
                    isLower = upCard.rank.value > current.rank.value ||
                        (upCard.rank.value == current.rank.value &&
                         upCard.suit.studOrder < current.suit.studOrder)
                } else {
                    isLower = upCard.rank.value < current.rank.value ||
                        (upCard.rank.value == current.rank.value &&
                         upCard.suit.studOrder < current.suit.studOrder)
                }
                if isLower {
                    lowestCard = upCard
                    lowestIndex = index
                }
            } else {
                lowestCard = upCard
                lowestIndex = index
            }
        }
        return lowestIndex
    }
}
