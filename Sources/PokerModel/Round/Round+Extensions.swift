import Foundation

extension Round {
    public var activePlayers: [RoundPlayer] {
        players.filter { $0.status == .in }
    }

    public var activePlayersNotAllIn: [RoundPlayer] {
        activePlayers.filter { $0.isAllIn == false }
    }

    public var maxOutstandingBet: Decimal {
        players.map { $0.currentBet }.max() ?? .zero
    }

    public var totalCollectedPot: Decimal {
        pots.map { $0.amount }.reduce(.zero, +)
    }

    public var totalPotAndBets: Decimal {
        totalCollectedPot + players.map { $0.currentBet }.reduce(.zero, +)
    }

    public var currentPlayerIndex: Int? {
        switch state {
        case .waitingForSmallBlind: return 0
        case .waitingForBigBlind: return 1
        case .waitingForAnte(let i): return i
        case .waitingForBringIn(let i): return i
        case .waitingForPlayerToAct(let i): return i
        default: return nil
        }
    }

    public var currentPlayer: RoundPlayer? {
        guard let idx: Int = currentPlayerIndex else { return nil }
        return players[idx]
    }

    public var canCheck: Bool {
        guard let cp: RoundPlayer = currentPlayer else { return false }
        return cp.currentBet >= maxOutstandingBet
    }

    public var minBetForCurrentPlayer: Decimal {
        guard let cp: RoundPlayer = currentPlayer else { return .zero }
        if cp.player.chipCount < blinds.bigBlind { return cp.player.chipCount }
        if maxOutstandingBet == .zero { return blinds.bigBlind }
        let amountToCall: Decimal = max(maxOutstandingBet, blinds.bigBlind) - cp.currentBet
        if cp.player.chipCount < amountToCall { return cp.player.chipCount }
        return amountToCall
    }

    public var minRaiseForCurrentPlayer: Decimal {
        guard let cp: RoundPlayer = currentPlayer else { return .zero }
        let prevRaise: Decimal = max(
            players.map { $0.currentBet }.sorted(by: >).first ?? .zero,
            blinds.bigBlind
        )
        let minRaise: Decimal = maxOutstandingBet + prevRaise - cp.currentBet
        return min(minRaise, cp.player.chipCount)
    }

    public var maxBetForCurrentPlayer: Decimal {
        guard let cp: RoundPlayer = currentPlayer else { return .zero }
        switch variant.bettingStructure {
        case .noLimit:
            return cp.player.chipCount
        case .fixedLimit:
            let betSize: Decimal = street.rawValue >= 2 ? blinds.bigBlind : blinds.smallBlind
            let amountToCall: Decimal = maxOutstandingBet - cp.currentBet
            return min(amountToCall + betSize, cp.player.chipCount)
        case .potLimit:
            let potTotal: Decimal = totalPotAndBets + (maxOutstandingBet - cp.currentBet)
            return min(potTotal, cp.player.chipCount)
        }
    }

    public func playerIndex(byID playerID: PlayerID) -> Int? {
        players.firstIndex(where: { $0.player.id == playerID })
    }

    public func roundPlayer(byID playerID: PlayerID) -> RoundPlayer? {
        players.first(where: { $0.player.id == playerID })
    }

    // MARK: - Card Resolution

    public func card(for id: CardID) -> Card {
        cardsMap[id]!
    }

    public func cards(for ids: [CardID]) -> [Card] {
        ids.map { cardsMap[$0]! }
    }

    public var dealerIndex: Int {
        if players.count <= 2 { 0 } else { players.count - 1 }
    }

    public var isComplete: Bool {
        if case .roundComplete = state { return true }
        return false
    }

    var isReadyForNextStreet: Bool {
        activePlayers.allSatisfy { p in
            if p.isAllIn { return true }
            guard p.hasActedThisStreet else { return false }
            return p.currentBet == maxOutstandingBet
        }
    }
}

extension Round.State {
    public var isWaitingForPlayerToAct: Bool {
        switch self {
        case .waitingForPlayerToAct: true
        default: false
        }
    }
}
