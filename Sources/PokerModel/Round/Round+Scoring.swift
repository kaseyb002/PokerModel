import Foundation

// MARK: - Pot Collection
extension Round {
    internal mutating func collectBets(
        restrictTo playerSubset: [RoundPlayer]? = nil
    ) {
        guard maxOutstandingBet > .zero else { return }

        let bettingPlayers: [RoundPlayer] = (playerSubset ?? players).filter { $0.currentBet > .zero }
        let bettingIds: Set<PlayerID> = Set(bettingPlayers.map { $0.player.id })

        if pots.isEmpty || pots[pots.count - 1].isFull {
            pots.append(.init(playerIds: bettingIds))
        }

        guard bettingPlayers.contains(where: { $0.isAllIn }) else {
            collectBetsSimple()
            return
        }

        let smallestAllInBet: Decimal = bettingPlayers
            .filter { $0.isAllIn }
            .map { $0.currentBet }
            .min() ?? .zero

        let overbetAmount: Decimal = bettingPlayers
            .filter { $0.status == .in }
            .map { $0.currentBet - smallestAllInBet }
            .reduce(.zero, +)

        guard overbetAmount > .zero else {
            collectBetsSimple()
            if overbetAmount == .zero { pots[pots.count - 1].isFull = true }
            return
        }

        let sidePotPlayers: [RoundPlayer] = bettingPlayers
            .filter { $0.currentBet > smallestAllInBet }

        if sidePotPlayers.count == 1,
           let playerID: PlayerID = sidePotPlayers.first?.player.id,
           let playerIdx: Int = playerIndex(byID: playerID) {
            let refund: Decimal = players[playerIdx].currentBet - smallestAllInBet
            players[playerIdx].currentBet = smallestAllInBet
            players[playerIdx].player.chipCount += refund
            collectBetsSimple()
            return
        }

        for bp in bettingPlayers {
            pots[pots.count - 1].amount += min(bp.currentBet, smallestAllInBet)
        }
        pots[pots.count - 1].isFull = true

        let sidePotIds: Set<PlayerID> = Set(sidePotPlayers.map { $0.player.id })
        pots.append(.init(playerIds: sidePotIds))

        for (i, p) in players.enumerated() {
            if sidePotIds.contains(p.player.id) {
                players[i].currentBet -= smallestAllInBet
            } else {
                players[i].currentBet = .zero
            }
        }

        collectBets(restrictTo: players.filter { sidePotIds.contains($0.player.id) })
    }

    private mutating func collectBetsSimple() {
        for (i, p) in players.enumerated() {
            pots[pots.count - 1].amount += p.currentBet
            players[i].currentBet = .zero
        }
    }
}

// MARK: - Completing the Round
extension Round {
    internal mutating func completeRound() {
        resetPlayersForNewStreet()
        let results: [PotResult] = evaluateWinners()
        self.potResults = results
        awardPots(results: results)

        state = .roundComplete
        ended = .init()
    }

    private func evaluateWinners() -> [PotResult] {
        var results: [PotResult] = []
        for pot in pots {
            let eligible: [RoundPlayer] = activePlayers.filter { pot.playerIds.contains($0.player.id) }

            if eligible.count <= 1 {
                if let winner: RoundPlayer = eligible.first {
                    let dummyHand: PokerHand = .fake()
                    let wh: WinningHand = .init(playerID: winner.player.id, pokerHand: dummyHand)
                    results.append(.init(pot: pot, highWinners: [wh]))
                }
                continue
            }

            switch variant {
            case .noLimitHoldEm, .limitHoldEm:
                let highWinners: Set<WinningHand> = evaluateHighHands(
                    eligible: eligible, evaluator: evaluateHoldEmHand
                )
                results.append(.init(pot: pot, highWinners: highWinners))

            case .noLimitOmaha, .potLimitOmaha:
                let highWinners: Set<WinningHand> = evaluateHighHands(
                    eligible: eligible, evaluator: evaluateOmahaHand
                )
                results.append(.init(pot: pot, highWinners: highWinners))

            case .pineapple:
                let highWinners: Set<WinningHand> = evaluateHighHands(
                    eligible: eligible, evaluator: evaluatePineappleHand
                )
                results.append(.init(pot: pot, highWinners: highWinners))

            case .fiveCardDraw:
                let highWinners: Set<WinningHand> = evaluateHighHands(
                    eligible: eligible, evaluator: evaluateDrawHand
                )
                results.append(.init(pot: pot, highWinners: highWinners))

            case .sevenCardStud:
                let highWinners: Set<WinningHand> = evaluateHighHands(
                    eligible: eligible, evaluator: evaluateStudHand
                )
                results.append(.init(pot: pot, highWinners: highWinners))

            case .razz:
                let lowWinners: Set<LowWinningHand> = evaluateRazzHands(eligible: eligible)
                results.append(.init(pot: pot, highWinners: [], lowWinners: lowWinners))

            case .studHighLow:
                let highWinners: Set<WinningHand> = evaluateHighHands(
                    eligible: eligible, evaluator: evaluateStudHand
                )
                let lowWinners: Set<LowWinningHand> = evaluateStudLowHands(eligible: eligible)
                results.append(.init(pot: pot, highWinners: highWinners, lowWinners: lowWinners))
            }
        }
        return results
    }

    // MARK: - High Hand Evaluation

    private func evaluateHighHands(
        eligible: [RoundPlayer],
        evaluator: (PlayerID) -> PokerHand?
    ) -> Set<WinningHand> {
        var winners: Set<WinningHand> = []
        for player in eligible {
            guard let hand: PokerHand = evaluator(player.player.id) else { continue }
            let wh: WinningHand = .init(playerID: player.player.id, pokerHand: hand)
            guard let currentBest: PokerHand = winners.first?.pokerHand else {
                winners = [wh]
                continue
            }
            let isBetter: Bool? = hand.topRank > currentBest.topRank
            if isBetter == true { winners = [wh] }
            else if isBetter == nil { winners.insert(wh) }
        }
        return winners
    }

    private func evaluateHoldEmHand(playerID: PlayerID) -> PokerHand? {
        guard case .noLimitHoldEm(let s) = variantRound else {
            guard case .limitHoldEm(let s) = variantRound else { return nil }
            guard let holeIDs: [CardID] = s.holeCards[playerID] else { return nil }
            let allCards: [Card] = cards(for: holeIDs) + cards(for: s.board)
            return try? allCards.bestPokerHand()
        }
        guard let holeIDs: [CardID] = s.holeCards[playerID] else { return nil }
        let allCards: [Card] = cards(for: holeIDs) + cards(for: s.board)
        return try? allCards.bestPokerHand()
    }

    private func evaluateOmahaHand(playerID: PlayerID) -> PokerHand? {
        let s: OmahaState
        switch variantRound {
        case .noLimitOmaha(let state): s = state
        case .potLimitOmaha(let state): s = state
        default: return nil
        }
        guard let holeIDs: [CardID] = s.holeCards[playerID] else { return nil }
        return try? cards(for: holeIDs).bestOmahaHand(board: cards(for: s.board))
    }

    private func evaluatePineappleHand(playerID: PlayerID) -> PokerHand? {
        guard case .pineapple(let s) = variantRound,
              let holeIDs: [CardID] = s.holeCards[playerID] else { return nil }
        let allCards: [Card] = cards(for: holeIDs) + cards(for: s.board)
        return try? allCards.bestPokerHand()
    }

    private func evaluateDrawHand(playerID: PlayerID) -> PokerHand? {
        guard case .fiveCardDraw(let s) = variantRound,
              let cardIDs: [CardID] = s.playerCards[playerID],
              cardIDs.count == 5 else { return nil }
        return try? PokerHand(cards: cards(for: cardIDs))
    }

    private func evaluateStudHand(playerID: PlayerID) -> PokerHand? {
        let s: StudState
        switch variantRound {
        case .sevenCardStud(let state): s = state
        case .studHighLow(let state): s = state
        default: return nil
        }
        guard let studCards: StudPlayerCards = s.playerCards[playerID] else { return nil }
        return try? cards(for: studCards.allCardIDs).bestPokerHand()
    }

    // MARK: - Low Hand Evaluation

    private func evaluateRazzHands(eligible: [RoundPlayer]) -> Set<LowWinningHand> {
        guard case .razz(let s) = variantRound else { return [] }
        var winners: Set<LowWinningHand> = []
        for player in eligible {
            guard let studCards: StudPlayerCards = s.playerCards[player.player.id],
                  let low: LowHand = LowHand.bestRazzHand(from: cards(for: studCards.allCardIDs)) else {
                continue
            }
            let lwh: LowWinningHand = .init(playerID: player.player.id, lowHand: low)
            guard let currentBest: LowHand = winners.first?.lowHand else {
                winners = [lwh]
                continue
            }
            if low.razzCompare(currentBest) { winners = [lwh] }
            else if low.ranks == currentBest.ranks { winners.insert(lwh) }
        }
        return winners
    }

    private func evaluateStudLowHands(eligible: [RoundPlayer]) -> Set<LowWinningHand> {
        guard case .studHighLow(let s) = variantRound else { return [] }
        var winners: Set<LowWinningHand> = []
        for player in eligible {
            guard let studCards: StudPlayerCards = s.playerCards[player.player.id],
                  let low: LowHand = LowHand.bestLowHand(from: cards(for: studCards.allCardIDs)) else { continue }
            let lwh: LowWinningHand = .init(playerID: player.player.id, lowHand: low)
            guard let currentBest: LowHand = winners.first?.lowHand else {
                winners = [lwh]
                continue
            }
            if low < currentBest { winners = [lwh] }
            else if low == currentBest { winners.insert(lwh) }
        }
        return winners
    }

    // MARK: - Awarding Pots

    private mutating func awardPots(results: [PotResult]) {
        for result in results {
            let totalWinnerCount: Int = result.highWinners.count + result.lowWinners.count
            guard totalWinnerCount > 0 else { continue }

            if result.lowWinners.isEmpty == false && result.highWinners.isEmpty == false {
                let halfPot: Decimal = (result.pot.amount / 2).roundToClosestPenny
                let otherHalf: Decimal = result.pot.amount - halfPot
                awardAmount(halfPot, to: Set(result.highWinners.map(\.playerID)))
                awardAmount(otherHalf, to: Set(result.lowWinners.map(\.playerID)))
            } else if result.highWinners.isEmpty == false {
                awardAmount(result.pot.amount, to: Set(result.highWinners.map(\.playerID)))
            } else {
                awardAmount(result.pot.amount, to: Set(result.lowWinners.map(\.playerID)))
            }
        }
    }

    private mutating func awardAmount(_ amount: Decimal, to playerIDs: Set<PlayerID>) {
        guard playerIDs.isEmpty == false else { return }
        if playerIDs.count == 1 {
            if let idx: Int = playerIndex(byID: playerIDs.first!) {
                players[idx].player.chipCount += amount
            }
            return
        }
        let perPlayer: Decimal = (amount / Decimal(playerIDs.count)).roundToClosestPenny
        let total: Decimal = perPlayer * Decimal(playerIDs.count)
        var remainder: Decimal = amount - total

        for pid in playerIDs {
            if let idx: Int = playerIndex(byID: pid) {
                players[idx].player.chipCount += perPlayer
            }
        }

        if remainder > .zero {
            let sorted: [PlayerID] = playerIDs.sorted { lhs, rhs in
                let lhsChips: Decimal = roundPlayer(byID: lhs)?.startingChipCount ?? .zero
                let rhsChips: Decimal = roundPlayer(byID: rhs)?.startingChipCount ?? .zero
                return lhsChips < rhsChips
            }
            for pid in sorted {
                guard remainder > .zero else { break }
                if let idx: Int = playerIndex(byID: pid) {
                    let award: Decimal = min(remainder, blinds.smallBlind)
                    players[idx].player.chipCount += award
                    remainder -= award
                }
            }
        }
    }
}
