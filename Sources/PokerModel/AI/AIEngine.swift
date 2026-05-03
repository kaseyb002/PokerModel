import Foundation

public final class AIEngine: Sendable {
    public enum Difficulty: String, Equatable, Codable, Sendable {
        case easy, medium, hard
    }

    public static func makeMove(in round: Round, difficulty: Difficulty, autoAdvance: Bool) -> Round {
        var updated: Round = round
        updated.makeMoveIfNeeded(difficulty: difficulty, autoAdvance: autoAdvance)
        return updated
    }
}

private extension Round {
    mutating func makeMoveIfNeeded(difficulty: AIEngine.Difficulty, autoAdvance: Bool) {
        guard isComplete == false else { return }
        switch state {
        case .waitingForSmallBlind: try? postSmallBlind()
        case .waitingForBigBlind: try? postBigBlind()
        case .waitingForAnte: try? postAnte()
        case .waitingForBringIn: try? postBringIn()
        case .waitingForPlayerToAct:
            guard let cp: RoundPlayer = currentPlayer, cp.isAllIn == false else { return }
            executeMove(chooseMove(difficulty: difficulty))
        case .waitingForDraw(let pid):
            try? drawCards(playerID: pid, discardIndices: chooseDrawDiscards(pid: pid, difficulty: difficulty))
        case .waitingForDiscard(let pid):
            try? discardCard(playerID: pid, cardIndex: choosePineappleDiscard(pid: pid))
        default: return
        }
        if autoAdvance { makeMoveIfNeeded(difficulty: difficulty, autoAdvance: true) }
    }

    func chooseMove(difficulty: AIEngine.Difficulty) -> AIMove {
        let strength: Int = currentHandStrength()
        switch difficulty {
        case .easy: return easyMove(strength: strength)
        case .medium: return mediumMove(strength: strength)
        case .hard: return hardMove(strength: strength)
        }
    }

    func currentHandStrength() -> Int {
        guard let cp: RoundPlayer = currentPlayer else { return 0 }
        let pid: PlayerID = cp.player.id
        switch variantRound {
        case .noLimitHoldEm(let s), .limitHoldEm(let s):
            guard let holeIDs: [CardID] = s.holeCards[pid] else { return 0 }
            let hole: [Card] = cards(for: holeIDs)
            if s.revealedBoardCount == 0 { return preflopStrength(hole) }
            return postflopStrength(hole + cards(for: Array(s.board.prefix(s.revealedBoardCount))))
        case .noLimitOmaha(let s), .potLimitOmaha(let s):
            guard let holeIDs: [CardID] = s.holeCards[pid] else { return 0 }
            let hole: [Card] = cards(for: holeIDs)
            if s.revealedBoardCount == 0 { return preflopStrength(hole) }
            let boardCards: [Card] = cards(for: Array(s.board.prefix(s.revealedBoardCount)))
            guard let h: PokerHand = try? hole.bestOmahaHand(board: boardCards) else { return 0 }
            return rankToStrength(h)
        case .pineapple(let s):
            guard let holeIDs: [CardID] = s.holeCards[pid] else { return 0 }
            let hole: [Card] = cards(for: holeIDs)
            if s.revealedBoardCount == 0 { return preflopStrength(hole) }
            return postflopStrength(hole + cards(for: Array(s.board.prefix(s.revealedBoardCount))))
        case .fiveCardDraw(let s):
            guard let cardIDs: [CardID] = s.playerCards[pid], cardIDs.count == 5,
                  let h: PokerHand = try? PokerHand(cards: cards(for: cardIDs)) else { return 0 }
            return rankToStrength(h)
        case .sevenCardStud(let s), .studHighLow(let s):
            guard let c: StudPlayerCards = s.playerCards[pid] else { return 0 }
            let allCards: [Card] = cards(for: c.allCardIDs)
            if allCards.count >= 5, let h: PokerHand = try? allCards.bestPokerHand() { return rankToStrength(h) }
            return preflopStrength(allCards)
        case .razz(let s):
            guard let c: StudPlayerCards = s.playerCards[pid] else { return 0 }
            let allCards: [Card] = cards(for: c.allCardIDs)
            let vals: [Int] = allCards.map { $0.rank.lowValue }.sorted()
            if Set(vals).count >= 5 && vals[4] <= 8 { return 5 }
            if vals.prefix(3).allSatisfy({ $0 <= 5 }) { return 3 }
            return 1
        }
    }

    func preflopStrength(_ cards: [Card]) -> Int {
        let ranks: [Card.Rank] = cards.map(\.rank).sorted(by: >)
        let hasPair: Bool = Set(ranks).count < ranks.count
        let high: Int = ranks.filter { $0.value >= 8 }.count
        if hasPair && ranks[0].value >= 8 { return 5 }
        if hasPair { return 3 }
        if high >= 2 { return 4 }
        if high >= 1 { return 2 }
        return 1
    }

    func postflopStrength(_ cards: [Card]) -> Int {
        guard let h: PokerHand = try? cards.bestPokerHand() else { return 0 }
        return rankToStrength(h)
    }

    func rankToStrength(_ hand: PokerHand) -> Int {
        switch hand.topRank {
        case .straightFlush, .fourOfAKind: 6
        case .fullHouse, .flush: 5
        case .straight, .threeOfAKind: 4
        case .twoPair: 3
        case .onePair: 2
        case .highCard: 1
        }
    }

    func easyMove(strength: Int) -> AIMove {
        switch strength {
        case 5...6: BoolExtensions.random(withProbability: 0.5) ? .call : .raise
        case 3...4: BoolExtensions.random(withProbability: 0.6) ? .call : .checkOrFold
        default: canCheck ? .checkOrFold : (BoolExtensions.random(withProbability: 0.6) ? .fold : .call)
        }
    }

    func mediumMove(strength: Int) -> AIMove {
        switch strength {
        case 5...6: BoolExtensions.random(withProbability: 0.7) ? .raise : .call
        case 4: BoolExtensions.random(withProbability: 0.4) ? .raise : .call
        case 3: BoolExtensions.random(withProbability: 0.7) ? .call : .checkOrFold
        case 2: canCheck ? .checkOrFold : (BoolExtensions.random(withProbability: 0.5) ? .call : .fold)
        default: canCheck ? .checkOrFold : (BoolExtensions.random(withProbability: 0.7) ? .fold : .call)
        }
    }

    func hardMove(strength: Int) -> AIMove {
        switch strength {
        case 5...6: BoolExtensions.random(withProbability: 0.3) ? .call : .raise
        case 4: BoolExtensions.random(withProbability: 0.5) ? .raise : .call
        case 3: BoolExtensions.random(withProbability: 0.6) ? .call : .fold
        case 2: canCheck ? .checkOrFold : (BoolExtensions.random(withProbability: 0.6) ? .fold : .call)
        default: canCheck ? .checkOrFold : (BoolExtensions.random(withProbability: 0.85) ? .fold : .call)
        }
    }

    mutating func executeMove(_ move: AIMove) {
        do {
            switch move {
            case .checkOrFold:
                if canCheck { try check() } else { try fold() }
            case .call:
                try call()
            case .raise:
                let amt: Decimal = blinds.bigBlind * 3
                if amt <= maxBetForCurrentPlayer { try bet(amount: amt) } else { try call() }
            case .fold:
                if canCheck { try check() } else { try fold() }
            }
        } catch {
            if canCheck { try? check() } else { try? fold() }
        }
    }

    func chooseDrawDiscards(pid: PlayerID, difficulty: AIEngine.Difficulty) -> [Int] {
        guard case .fiveCardDraw(let s) = variantRound,
              let cardIDs: [CardID] = s.playerCards[pid] else { return [] }
        let playerCards: [Card] = cards(for: cardIDs)
        let rankCounts: [Card.Rank: Int] = Dictionary(grouping: playerCards.map(\.rank), by: { $0 }).mapValues(\.count)
        var keep: Set<Int> = []
        for (i, c) in playerCards.enumerated() {
            if let cnt: Int = rankCounts[c.rank], cnt >= 2 { keep.insert(i) }
        }
        if keep.isEmpty {
            let sorted: [(Int, Card)] = playerCards.enumerated().sorted { $0.1.rank > $1.1.rank }
            for i in 0..<min(difficulty == .easy ? 1 : 2, sorted.count) { keep.insert(sorted[i].0) }
        }
        return (0..<playerCards.count).filter { keep.contains($0) == false }
    }

    func choosePineappleDiscard(pid: PlayerID) -> Int {
        guard case .pineapple(let s) = variantRound,
              let cardIDs: [CardID] = s.holeCards[pid] else { return 0 }
        let playerCards: [Card] = cards(for: cardIDs)
        var worst: Int = 0
        for (i, c) in playerCards.enumerated() { if c.rank.value < playerCards[worst].rank.value { worst = i } }
        return worst
    }
}

private enum AIMove { case checkOrFold, call, raise, fold }
