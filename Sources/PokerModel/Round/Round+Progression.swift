import Foundation

// MARK: - State Machine
extension Round {
    public mutating func moveToNextState() {
        guard activePlayers.count > 1 else {
            collectBets()
            completeRound()
            return
        }

        switch state {
        case .waitingForSmallBlind:
            state = .waitingForBigBlind

        case .waitingForBigBlind, .waitingForPlayerToAct, .waitingForBringIn:
            if isReadyForNextStreet {
                state = .waitingToProgressStreet
                if autoProgress { progressStreetIfReady() }
            } else {
                findNextPlayer()
            }

        case .waitingToProgressStreet:
            if autoProgress { progressStreetIfReady() }

        case .waitingForAnte, .waitingForDiscard, .waitingForDraw, .roundComplete:
            break
        }
    }

    public mutating func progressStreetIfReady() {
        guard isReadyForNextStreet else { return }
        collectBets()

        let maxStreet: Int = variant.streetCount - 1
        let nextStreetRaw: Int = street.rawValue + 1

        if nextStreetRaw > maxStreet {
            completeRound()
            return
        }

        guard let nextStreet: Street = Street(rawValue: nextStreetRaw) else {
            completeRound()
            return
        }

        street = nextStreet
        advanceVariantState()

        if activePlayersNotAllIn.count <= 1 && activePlayers.count > 1 {
            collectBets()
            if autoProgress {
                if let finalStreet: Street = Street(rawValue: maxStreet), street < finalStreet {
                    street = finalStreet
                    advanceVariantToFinal()
                }
                completeRound()
                return
            }
        }

        resetPlayersForNewStreet()

        if variant.isStudVariant {
            resetCurrentPlayerForStudStreet()
        } else {
            resetCurrentPlayerForNextStreet()
        }
    }

    // MARK: - Advance Variant State

    private mutating func advanceVariantState() {
        switch variantRound {
        case .noLimitHoldEm(var s), .limitHoldEm(var s):
            advanceCommunityCards(state: &s)
            if case .noLimitHoldEm = variantRound {
                variantRound = .noLimitHoldEm(s)
            } else {
                variantRound = .limitHoldEm(s)
            }

        case .noLimitOmaha(var s), .potLimitOmaha(var s):
            advanceOmahaBoard(state: &s)
            if case .noLimitOmaha = variantRound {
                variantRound = .noLimitOmaha(s)
            } else {
                variantRound = .potLimitOmaha(s)
            }

        case .pineapple(var s):
            advancePineappleBoard(state: &s)
            variantRound = .pineapple(s)

        case .razz(var s), .sevenCardStud(var s), .studHighLow(var s):
            dealNextStudStreet(state: &s)
            switch variant {
            case .razz: variantRound = .razz(s)
            case .studHighLow: variantRound = .studHighLow(s)
            default: variantRound = .sevenCardStud(s)
            }

        case .fiveCardDraw(var s):
            if s.drawComplete == false {
                let drawOrder: [PlayerID] = activePlayers.map(\.player.id)
                s.pendingDrawPlayerIDs = drawOrder
                variantRound = .fiveCardDraw(s)
                if let firstID: PlayerID = drawOrder.first {
                    state = .waitingForDraw(playerID: firstID)
                }
                return
            }
        }
    }

    private mutating func advanceVariantToFinal() {
        switch variantRound {
        case .noLimitHoldEm(var s), .limitHoldEm(var s):
            s.revealedBoardCount = 5
            if case .noLimitHoldEm = variantRound {
                variantRound = .noLimitHoldEm(s)
            } else { variantRound = .limitHoldEm(s) }

        case .noLimitOmaha(var s), .potLimitOmaha(var s):
            s.revealedBoardCount = 5
            if case .noLimitOmaha = variantRound {
                variantRound = .noLimitOmaha(s)
            } else { variantRound = .potLimitOmaha(s) }

        case .pineapple(var s):
            s.revealedBoardCount = 5
            variantRound = .pineapple(s)

        case .razz(var s), .sevenCardStud(var s), .studHighLow(var s):
            while s.currentStreetIndex < 4 {
                dealNextStudStreet(state: &s)
            }
            switch variant {
            case .razz: variantRound = .razz(s)
            case .studHighLow: variantRound = .studHighLow(s)
            default: variantRound = .sevenCardStud(s)
            }

        case .fiveCardDraw:
            break
        }
    }

    private func advanceCommunityCards(state: inout HoldEmState) {
        switch street {
        case .second: state.revealedBoardCount = 3
        case .third: state.revealedBoardCount = 4
        case .fourth: state.revealedBoardCount = 5
        default: break
        }
    }

    private func advanceOmahaBoard(state: inout OmahaState) {
        switch street {
        case .second: state.revealedBoardCount = 3
        case .third: state.revealedBoardCount = 4
        case .fourth: state.revealedBoardCount = 5
        default: break
        }
    }

    private mutating func advancePineappleBoard(state: inout PineappleState) {
        switch street {
        case .second:
            state.revealedBoardCount = 3
            let discardOrder: [PlayerID] = activePlayers.map(\.player.id)
            state.pendingDiscardPlayerIDs = discardOrder
            variantRound = .pineapple(state)
            if let firstID: PlayerID = discardOrder.first {
                self.state = .waitingForDiscard(playerID: firstID)
            }
            return
        case .third: state.revealedBoardCount = 4
        case .fourth: state.revealedBoardCount = 5
        default: break
        }
    }

    private mutating func dealNextStudStreet(state: inout StudState) {
        state.currentStreetIndex += 1
        let isFinalStreet: Bool = state.currentStreetIndex >= 4
        for player in activePlayers {
            guard var studCards: StudPlayerCards = state.playerCards[player.player.id],
                  state.deck.isEmpty == false else { continue }
            let cardID: CardID = state.deck.removeLast()
            if isFinalStreet {
                studCards.downCards.append(cardID)
            } else {
                studCards.upCards.append(cardID)
            }
            state.playerCards[player.player.id] = studCards
        }
    }

    // MARK: - Finding Next Player

    internal mutating func findNextPlayer() {
        guard let idx: Int = currentPlayerIndex else { return }
        var nextIdx: Int = idx + 1
        let count: Int = players.count

        while nextIdx != idx {
            if nextIdx >= count { nextIdx = 0 }
            if nextIdx == idx { break }
            let p: RoundPlayer = players[nextIdx]
            if p.status == .out { nextIdx += 1; continue }
            if p.isAllIn { nextIdx += 1; continue }
            if p.hasActedThisStreet == false || p.currentBet < maxOutstandingBet {
                state = .waitingForPlayerToAct(playerIndex: nextIdx)
                autoCheckIfAllIn()
                return
            }
            nextIdx += 1
        }

        state = .waitingToProgressStreet
        if autoProgress { progressStreetIfReady() }
    }

    internal mutating func resetPlayersForNewStreet() {
        for i in 0..<players.count {
            players[i].hasActedThisStreet = false
        }
    }

    internal mutating func resetCurrentPlayerForNextStreet() {
        for (index, player) in players.enumerated() {
            if player.status == .in && player.isAllIn == false {
                state = .waitingForPlayerToAct(playerIndex: index)
                autoCheckIfAllIn()
                return
            }
        }
    }

    internal mutating func resetCurrentPlayerForStudStreet() {
        guard let bestIdx: Int = findHighestShowingHand() else {
            resetCurrentPlayerForNextStreet()
            return
        }
        state = .waitingForPlayerToAct(playerIndex: bestIdx)
        autoCheckIfAllIn()
    }

    private func findHighestShowingHand() -> Int? {
        var bestIdx: Int?
        var bestRank: Card.Rank?
        for (index, player) in players.enumerated() {
            guard player.status == .in else { continue }
            let upCardIDs: [CardID]
            switch variantRound {
            case .razz(let s), .sevenCardStud(let s), .studHighLow(let s):
                upCardIDs = s.playerCards[player.player.id]?.upCards ?? []
            default: return nil
            }
            let upCards: [Card] = cards(for: upCardIDs)
            guard let highest: Card = upCards.max(by: { $0.rank < $1.rank }) else { continue }
            if variant == .razz {
                if let best: Card.Rank = bestRank {
                    if highest.rank < best {
                        bestRank = highest.rank
                        bestIdx = index
                    }
                } else {
                    bestRank = highest.rank
                    bestIdx = index
                }
            } else {
                if let best: Card.Rank = bestRank {
                    if highest.rank > best {
                        bestRank = highest.rank
                        bestIdx = index
                    }
                } else {
                    bestRank = highest.rank
                    bestIdx = index
                }
            }
        }
        return bestIdx
    }

    private mutating func autoCheckIfAllIn() {
        guard let cp: RoundPlayer = currentPlayer,
              cp.isAllIn,
              isComplete == false else { return }
        try? check()
    }
}
