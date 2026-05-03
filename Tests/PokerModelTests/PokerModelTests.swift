import Foundation
import Testing
@testable import PokerModel

// MARK: - Card Tests

@Test func cardInitialization() {
    let card: Card = Card(rank: .ace, suit: .spade)
    #expect(card.rank == .ace)
    #expect(card.suit == .spade)
    #expect(card.id == "as")
}

@Test func cardFromID() {
    let card: Card? = Card(id: "ah")
    #expect(card != nil)
    #expect(card?.rank == .ace)
    #expect(card?.suit == .heart)
}

@Test func deckHas52Cards() {
    let deck: Deck = .init()
    #expect(deck.cards.count == 52)
}

// MARK: - PokerHand Tests

@Test func straightFlushDetection() throws {
    let cards: [Card] = [
        Card(rank: .ten, suit: .spade), Card(rank: .jack, suit: .spade),
        Card(rank: .queen, suit: .spade), Card(rank: .king, suit: .spade),
        Card(rank: .ace, suit: .spade),
    ]
    let hand: PokerHand = try .init(cards: cards)
    #expect(hand.topRank.displayName == "Royal Flush")
}

@Test func fullHouseDetection() throws {
    let cards: [Card] = [
        Card(rank: .king, suit: .spade), Card(rank: .king, suit: .heart),
        Card(rank: .king, suit: .diamond), Card(rank: .three, suit: .club),
        Card(rank: .three, suit: .heart),
    ]
    let hand: PokerHand = try .init(cards: cards)
    #expect(hand.topRank.displayName == "Full House")
}

@Test func pairDetection() throws {
    let cards: [Card] = [
        Card(rank: .ace, suit: .spade), Card(rank: .ace, suit: .heart),
        Card(rank: .king, suit: .diamond), Card(rank: .queen, suit: .club),
        Card(rank: .jack, suit: .heart),
    ]
    let hand: PokerHand = try .init(cards: cards)
    #expect(hand.topRank.displayName == "Pair")
}

@Test func bestHandFromSeven() throws {
    let cards: [Card] = [
        Card(rank: .ace, suit: .spade), Card(rank: .ace, suit: .heart),
        Card(rank: .king, suit: .diamond), Card(rank: .king, suit: .club),
        Card(rank: .queen, suit: .heart), Card(rank: .two, suit: .club),
        Card(rank: .three, suit: .diamond),
    ]
    let best: PokerHand = try cards.bestPokerHand()
    #expect(best.topRank.displayName == "Two Pair")
}

@Test func omahaHandEvaluation() throws {
    let hole: [Card] = [
        Card(rank: .ace, suit: .spade), Card(rank: .king, suit: .spade),
        Card(rank: .two, suit: .heart), Card(rank: .three, suit: .diamond),
    ]
    let board: [Card] = [
        Card(rank: .ace, suit: .heart), Card(rank: .king, suit: .heart),
        Card(rank: .queen, suit: .club), Card(rank: .jack, suit: .diamond),
        Card(rank: .ten, suit: .spade),
    ]
    let best: PokerHand = try hole.bestOmahaHand(board: board)
    #expect(best.topRank.rankLevel >= 4)
}

// MARK: - LowHand Tests

@Test func lowHandDetection() {
    let cards: [Card] = [
        Card(rank: .ace, suit: .spade), Card(rank: .two, suit: .heart),
        Card(rank: .three, suit: .club), Card(rank: .four, suit: .diamond),
        Card(rank: .five, suit: .spade),
    ]
    let low: LowHand? = LowHand(cards: cards)
    #expect(low != nil)
}

@Test func lowHandRejectsHighCards() {
    let cards: [Card] = [
        Card(rank: .nine, suit: .spade), Card(rank: .ten, suit: .heart),
        Card(rank: .jack, suit: .club), Card(rank: .queen, suit: .diamond),
        Card(rank: .king, suit: .spade),
    ]
    let low: LowHand? = LowHand(cards: cards)
    #expect(low == nil)
}

// MARK: - Variant Tests

@Test func variantMaxPlayers() {
    #expect(Variant.noLimitHoldEm.maxPlayers == 10)
    #expect(Variant.fiveCardDraw.maxPlayers == 6)
    #expect(Variant.sevenCardStud.maxPlayers == 8)
    #expect(Variant.razz.maxPlayers == 8)
}

// MARK: - Round Init Tests

@Test func roundInitNoLimitHoldEm() throws {
    let round: Round = try .fake(variant: .noLimitHoldEm)
    #expect(round.variant == .noLimitHoldEm)
    #expect(round.players.count == 4)
    if case .waitingForSmallBlind = round.state {} else {
        #expect(Bool(false), "Expected waitingForSmallBlind")
    }
}

@Test func roundInitLimitHoldEm() throws {
    let round: Round = try .fake(variant: .limitHoldEm)
    #expect(round.variant == .limitHoldEm)
}

@Test func roundInitNoLimitOmaha() throws {
    let round: Round = try .fake(variant: .noLimitOmaha)
    #expect(round.variant == .noLimitOmaha)
    if case .noLimitOmaha(let s) = round.variantRound {
        for (_, cards) in s.holeCards { #expect(cards.count == 4) }
    }
}

@Test func roundInitPotLimitOmaha() throws {
    let round: Round = try .fake(variant: .potLimitOmaha)
    #expect(round.variant == .potLimitOmaha)
}

@Test func roundInitPineapple() throws {
    let round: Round = try .fake(variant: .pineapple)
    #expect(round.variant == .pineapple)
    if case .pineapple(let s) = round.variantRound {
        for (_, cards) in s.holeCards { #expect(cards.count == 3) }
    }
}

@Test func roundInitFiveCardDraw() throws {
    let round: Round = try .fake(variant: .fiveCardDraw)
    #expect(round.variant == .fiveCardDraw)
    if case .fiveCardDraw(let s) = round.variantRound {
        for (_, cards) in s.playerCards { #expect(cards.count == 5) }
    }
}

@Test func roundInitSevenCardStud() throws {
    let players: [Player] = (1...4).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1500) }
    let round: Round = try .init(variant: .sevenCardStud, blinds: .init(25, 50, ante: 5), players: players)
    #expect(round.variant == .sevenCardStud)
    if case .sevenCardStud(let s) = round.variantRound {
        for (_, cards) in s.playerCards {
            #expect(cards.downCards.count == 2)
            #expect(cards.upCards.count == 1)
        }
    }
}

@Test func roundInitRazz() throws {
    let players: [Player] = (1...4).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1500) }
    let round: Round = try .init(variant: .razz, blinds: .init(25, 50, ante: 5), players: players)
    #expect(round.variant == .razz)
}

@Test func roundInitStudHighLow() throws {
    let players: [Player] = (1...4).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1500) }
    let round: Round = try .init(variant: .studHighLow, blinds: .init(25, 50, ante: 5), players: players)
    #expect(round.variant == .studHighLow)
}

@Test func roundRejectsTooFewPlayers() {
    #expect(throws: PokerError.self) {
        try Round(variant: .noLimitHoldEm, blinds: .init(25, 50),
                  players: [.fake(id: "1", name: "Solo", chipCount: 1000)])
    }
}

@Test func roundRejectsTooManyPlayers() {
    let players: [Player] = (1...11).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1000) }
    #expect(throws: PokerError.self) {
        try Round(variant: .noLimitHoldEm, blinds: .init(25, 50), players: players)
    }
}

// MARK: - Betting Tests

@Test func postBlindsAndBet() throws {
    var round: Round = try .fake()
    try round.postSmallBlind()
    if case .waitingForBigBlind = round.state {} else {
        #expect(Bool(false), "Expected waitingForBigBlind")
    }
    try round.postBigBlind()
    #expect(round.state.isWaitingForPlayerToAct)
}

@Test func checkAndFold() throws {
    var round: Round = try .fake()
    try round.postSmallBlind()
    try round.postBigBlind()
    // Players should be able to act now
    if case .waitingForPlayerToAct = round.state {
        try round.call()
    }
}

// MARK: - Full Round Playthrough Tests

@Test func fullHoldEmRoundWithAI() throws {
    var round: Round = try .fake(variant: .noLimitHoldEm)
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    #expect(round.ended != nil)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullLimitHoldEmRoundWithAI() throws {
    var round: Round = try .fake(variant: .limitHoldEm)
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullOmahaRoundWithAI() throws {
    var round: Round = try .fake(variant: .noLimitOmaha)
    round = AIEngine.makeMove(in: round, difficulty: .easy, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullPotLimitOmahaRoundWithAI() throws {
    var round: Round = try .fake(variant: .potLimitOmaha)
    round = AIEngine.makeMove(in: round, difficulty: .easy, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullDrawRoundWithAI() throws {
    var round: Round = try .fake(variant: .fiveCardDraw)
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullPineappleRoundWithAI() throws {
    var round: Round = try .fake(variant: .pineapple)
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullStudRoundWithAI() throws {
    let players: [Player] = (1...4).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1500) }
    var round: Round = try .init(variant: .sevenCardStud, blinds: .init(25, 50, ante: 5), players: players)
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullRazzRoundWithAI() throws {
    let players: [Player] = (1...4).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1500) }
    var round: Round = try .init(variant: .razz, blinds: .init(25, 50, ante: 5), players: players)
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

@Test func fullStudHighLowRoundWithAI() throws {
    let players: [Player] = (1...4).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1500) }
    var round: Round = try .init(variant: .studHighLow, blinds: .init(25, 50, ante: 5), players: players)
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 6000)
}

// MARK: - AI Difficulty Tests

@Test func aiDifficultyLevels() throws {
    for difficulty in [AIEngine.Difficulty.easy, .medium, .hard] {
        var round: Round = try .fake(variant: .noLimitHoldEm)
        round = AIEngine.makeMove(in: round, difficulty: difficulty, autoAdvance: true)
        #expect(round.isComplete)
    }
}

// MARK: - Codable Tests

@Test func roundEncodesAndDecodes() throws {
    let round: Round = try .fake()
    let encoder: JSONEncoder = .init()
    let data: Data = try encoder.encode(round)
    let decoder: JSONDecoder = .init()
    let decoded: Round = try decoder.decode(Round.self, from: data)
    #expect(decoded.id == round.id)
    #expect(decoded.variant == round.variant)
}

// MARK: - Side Pot Tests

@Test func sidePotCreation() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Short", chipCount: 200),
        .fake(id: "2", name: "Medium", chipCount: 500),
        .fake(id: "3", name: "Deep", chipCount: 1000),
    ]
    var round: Round = try Round(variant: .noLimitHoldEm, blinds: .init(25, 50), players: players, cookedDeck: .fake())
    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 1700)
}

@Test func sidePotTwoAllIns() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Tiny", chipCount: 100),
        .fake(id: "2", name: "Short", chipCount: 300),
        .fake(id: "3", name: "Deep", chipCount: 1000),
    ]
    var round: Round = try Round(
        variant: .noLimitHoldEm, blinds: .init(25, 50),
        players: players, cookedDeck: .fake()
    )
    try round.postSmallBlind()
    try round.postBigBlind()

    // Player 3 (UTG) goes all-in for 1000
    try round.bet(amount: 1000)
    // Player 1 (SB) calls all-in for remaining 75
    try round.call()
    // Player 2 (BB) calls all-in for remaining 250
    try round.call()

    #expect(round.isComplete)
    #expect(round.pots.count >= 2)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 1400)
}

@Test func sidePotThreePlayersMultiplePots() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Tiny", chipCount: 50),
        .fake(id: "2", name: "Small", chipCount: 150),
        .fake(id: "3", name: "Medium", chipCount: 400),
        .fake(id: "4", name: "Big", chipCount: 800),
    ]
    var round: Round = try Round(
        variant: .noLimitHoldEm, blinds: .init(10, 20),
        players: players, cookedDeck: .fake()
    )
    try round.postSmallBlind()
    try round.postBigBlind()

    // P3 raises to 400 (all-in)
    try round.bet(amount: 400)
    // P4 calls 400
    try round.call()
    // P1 calls all-in (40 remaining after SB)
    try round.call()
    // P2 calls all-in (130 remaining after BB)
    try round.call()

    #expect(round.isComplete)
    #expect(round.pots.count >= 3)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 1400)
}

@Test func smallBlindExceedsPlayerChips() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Broke", chipCount: 10),
        .fake(id: "2", name: "Rich", chipCount: 1000),
        .fake(id: "3", name: "Average", chipCount: 500),
    ]
    var round: Round = try Round(
        variant: .noLimitHoldEm, blinds: .init(25, 50),
        players: players, cookedDeck: .fake()
    )

    try round.postSmallBlind()
    #expect(round.players[0].currentBet == 10)
    #expect(round.players[0].player.chipCount == 0)

    try round.postBigBlind()
    #expect(round.players[1].currentBet == 50)

    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 1510)
}

@Test func bigBlindExceedsPlayerChips() throws {
    let players: [Player] = [
        .fake(id: "1", name: "SB", chipCount: 500),
        .fake(id: "2", name: "BrokeBB", chipCount: 30),
        .fake(id: "3", name: "Average", chipCount: 500),
    ]
    var round: Round = try Round(
        variant: .noLimitHoldEm, blinds: .init(25, 50),
        players: players, cookedDeck: .fake()
    )

    try round.postSmallBlind()
    #expect(round.players[0].currentBet == 25)

    try round.postBigBlind()
    #expect(round.players[1].currentBet == 30)
    #expect(round.players[1].player.chipCount == 0)

    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 1030)
}

@Test func bothBlindsExceedPlayerChips() throws {
    let players: [Player] = [
        .fake(id: "1", name: "BrokeSB", chipCount: 15),
        .fake(id: "2", name: "BrokeBB", chipCount: 20),
        .fake(id: "3", name: "Rich", chipCount: 1000),
    ]
    var round: Round = try Round(
        variant: .noLimitHoldEm, blinds: .init(25, 50),
        players: players, cookedDeck: .fake()
    )

    try round.postSmallBlind()
    #expect(round.players[0].currentBet == 15)
    #expect(round.players[0].player.chipCount == 0)

    try round.postBigBlind()
    #expect(round.players[1].currentBet == 20)
    #expect(round.players[1].player.chipCount == 0)

    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 1035)
}

@Test func anteExceedsPlayerChips() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Broke", chipCount: 3),
        .fake(id: "2", name: "Short", chipCount: 50),
        .fake(id: "3", name: "Rich", chipCount: 500),
    ]
    var round: Round = try Round(
        variant: .sevenCardStud, blinds: .init(25, 50, ante: 10),
        players: players, cookedDeck: .fake()
    )

    try round.postAnte()
    #expect(round.players[0].player.chipCount == 0)
    #expect(round.players[0].currentBet == 3)

    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 553)
}

@Test func sidePotChipConservation() throws {
    for _ in 0..<10 {
        let players: [Player] = [
            .fake(id: "1", name: "P1", chipCount: Decimal(Int.random(in: 50...500))),
            .fake(id: "2", name: "P2", chipCount: Decimal(Int.random(in: 50...500))),
            .fake(id: "3", name: "P3", chipCount: Decimal(Int.random(in: 50...500))),
        ]
        let expectedTotal: Decimal = players.map(\.chipCount).reduce(.zero, +)
        var round: Round = try Round(
            variant: .noLimitHoldEm, blinds: .init(10, 20), players: players
        )
        round = AIEngine.makeMove(in: round, difficulty: .hard, autoAdvance: true)
        #expect(round.isComplete)

        let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
        #expect(totalChips == expectedTotal)
    }
}

@Test func sidePotAllInPreflop() throws {
    let players: [Player] = [
        .fake(id: "1", name: "SB", chipCount: 100),
        .fake(id: "2", name: "BB", chipCount: 100),
        .fake(id: "3", name: "BTN", chipCount: 100),
    ]
    var round: Round = try Round(
        variant: .noLimitHoldEm, blinds: .init(25, 50),
        players: players, cookedDeck: .fake()
    )

    try round.postSmallBlind()
    try round.postBigBlind()

    // BTN goes all-in
    try round.bet(amount: 100)
    // SB calls all-in
    try round.call()
    // BB calls all-in
    try round.call()

    #expect(round.isComplete)
    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 300)
}

@Test func sidePotOmahaMultipleAllIns() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Micro", chipCount: 40),
        .fake(id: "2", name: "Small", chipCount: 120),
        .fake(id: "3", name: "Med", chipCount: 300),
        .fake(id: "4", name: "Big", chipCount: 600),
    ]
    var round: Round = try Round(
        variant: .potLimitOmaha, blinds: .init(10, 20),
        players: players, cookedDeck: .fake()
    )

    round = AIEngine.makeMove(in: round, difficulty: .easy, autoAdvance: true)
    #expect(round.isComplete)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 1060)
}

@Test func sidePotDrawVariant() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Short", chipCount: 30),
        .fake(id: "2", name: "Mid", chipCount: 200),
        .fake(id: "3", name: "Deep", chipCount: 500),
    ]
    var round: Round = try Round(
        variant: .fiveCardDraw, blinds: .init(10, 20),
        players: players, cookedDeck: .fake()
    )

    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 730)
}

@Test func sidePotStudVariant() throws {
    let players: [Player] = [
        .fake(id: "1", name: "Short", chipCount: 30),
        .fake(id: "2", name: "Mid", chipCount: 200),
        .fake(id: "3", name: "Deep", chipCount: 500),
    ]
    var round: Round = try Round(
        variant: .sevenCardStud, blinds: .init(10, 20, ante: 5),
        players: players, cookedDeck: .fake()
    )

    round = AIEngine.makeMove(in: round, difficulty: .medium, autoAdvance: true)
    #expect(round.isComplete)

    let totalChips: Decimal = round.players.map(\.player.chipCount).reduce(.zero, +)
    #expect(totalChips == 730)
}

// MARK: - CardsMap Tests

@Test func cardsMapContainsAllDealtCards() throws {
    let round: Round = try .fake(variant: .noLimitHoldEm)
    guard case .noLimitHoldEm(let s) = round.variantRound else {
        #expect(Bool(false), "Expected hold'em state")
        return
    }
    let allIDs: [CardID] = s.holeCards.values.flatMap { $0 } + s.board
    for id in allIDs {
        #expect(round.cardsMap[id] != nil, "Card \(id) missing from cardsMap")
    }
    #expect(allIDs.count == 4 * 2 + 5)
}

@Test func cardsMapStudContainsAllCards() throws {
    let players: [Player] = (1...4).map { .fake(id: "\($0)", name: "P\($0)", chipCount: 1500) }
    let round: Round = try .init(variant: .sevenCardStud, blinds: .init(25, 50, ante: 5), players: players)
    guard case .sevenCardStud(let s) = round.variantRound else {
        #expect(Bool(false), "Expected stud state")
        return
    }
    let dealtIDs: [CardID] = s.playerCards.values.flatMap { $0.allCardIDs }
    let deckIDs: [CardID] = s.deck
    for id in dealtIDs + deckIDs {
        #expect(round.cardsMap[id] != nil, "Card \(id) missing from cardsMap")
    }
}

@Test func cardResolutionFromCardsMap() throws {
    let round: Round = try .fake(variant: .noLimitHoldEm)
    guard case .noLimitHoldEm(let s) = round.variantRound else {
        #expect(Bool(false))
        return
    }
    let holeIDs: [CardID] = s.holeCards.values.first!
    let resolvedCards: [Card] = round.cards(for: holeIDs)
    #expect(resolvedCards.count == holeIDs.count)
    for (id, card) in zip(holeIDs, resolvedCards) {
        #expect(card.id == id)
    }
}
