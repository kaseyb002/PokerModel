import Foundation

// MARK: - Posting Blinds & Antes
extension Round {
    public mutating func postSmallBlind() throws {
        guard case .waitingForSmallBlind = state else {
            throw PokerError.blindAlreadyPosted
        }
        let blindBet: Decimal = min(blinds.smallBlind, players[0].player.chipCount)
        players[0].currentBet = blindBet
        players[0].player.chipCount -= blindBet
        log.addAction(.init(playerID: players[0].player.id, decision: .postSmallBlind(amount: blindBet)))
        state = .waitingForBigBlind
    }

    public mutating func postBigBlind() throws {
        guard case .waitingForBigBlind = state else {
            throw PokerError.blindAlreadyPosted
        }
        let blindBet: Decimal = min(blinds.bigBlind, players[1].player.chipCount)
        players[1].currentBet = blindBet
        players[1].player.chipCount -= blindBet
        log.addAction(.init(playerID: players[1].player.id, decision: .postBigBlind(amount: blindBet)))
        moveToNextState()
    }

    public mutating func postAnte() throws {
        guard case .waitingForAnte(let idx) = state else {
            throw PokerError.invalidAction
        }
        let anteAmount: Decimal = min(blinds.ante, players[idx].player.chipCount)
        players[idx].currentBet = anteAmount
        players[idx].player.chipCount -= anteAmount
        log.addAction(.init(playerID: players[idx].player.id, decision: .postAnte(amount: anteAmount)))

        let nextIdx: Int = idx + 1
        if nextIdx < players.count {
            state = .waitingForAnte(playerIndex: nextIdx)
        } else {
            collectBets()
            switch self.variantRound {
            case .razz(let s), .sevenCardStud(let s), .studHighLow(let s):
                let bringInIdx: Int = Self.findBringInPlayer(
                    studState: s, players: players.map(\.player), variant: variant,
                    cardsMap: cardsMap
                )
                state = .waitingForBringIn(playerIndex: bringInIdx)
            default:
                moveToNextState()
            }
        }
    }

    public mutating func postBringIn() throws {
        guard case .waitingForBringIn(let idx) = state else {
            throw PokerError.bringInAlreadyPosted
        }
        let bringInAmount: Decimal = min(blinds.smallBlind, players[idx].player.chipCount)
        players[idx].currentBet = bringInAmount
        players[idx].player.chipCount -= bringInAmount
        players[idx].hasActedThisStreet = true
        log.addAction(.init(playerID: players[idx].player.id, decision: .postBringIn(amount: bringInAmount)))
        moveToNextState()
    }
}

// MARK: - Betting Actions
extension Round {
    public mutating func bet(amount: Decimal) throws {
        guard let idx: Int = currentPlayerIndex,
              case .waitingForPlayerToAct = state else {
            throw PokerError.noCurrentPlayer
        }
        guard isComplete == false else { throw PokerError.roundAlreadyComplete }

        let validBet: Decimal = min(maxBetForCurrentPlayer, amount).roundToClosestPenny
        guard validBet >= minBetForCurrentPlayer else {
            throw PokerError.insufficientBet
        }

        if maxOutstandingBet > .zero && validBet > minBetForCurrentPlayer {
            guard validBet >= minRaiseForCurrentPlayer else {
                throw PokerError.insufficientRaise
            }
        }

        let didCall: Bool = amount == maxOutstandingBet - players[idx].currentBet
        players[idx].currentBet += validBet
        players[idx].player.chipCount -= validBet
        players[idx].hasActedThisStreet = true

        let isAllIn: Bool = players[idx].player.chipCount == .zero
        let decision: Log.PlayerAction.Decision = didCall
            ? .call(amount: validBet, isAllIn: isAllIn)
            : .bet(amount: validBet, isAllIn: isAllIn)
        log.addAction(.init(playerID: players[idx].player.id, decision: decision))
        moveToNextState()
    }

    public mutating func call() throws {
        guard let cp: RoundPlayer = currentPlayer else {
            throw PokerError.noCurrentPlayer
        }
        if cp.player.chipCount < max(maxOutstandingBet, blinds.bigBlind) {
            try bet(amount: cp.player.chipCount)
        } else {
            try bet(amount: max(maxOutstandingBet, blinds.bigBlind) - cp.currentBet)
        }
    }

    public mutating func check() throws {
        guard let idx: Int = currentPlayerIndex,
              case .waitingForPlayerToAct = state else {
            throw PokerError.noCurrentPlayer
        }
        guard canCheck else { throw PokerError.cannotCheckWhenOutstandingBet }
        players[idx].hasActedThisStreet = true
        log.addAction(.init(playerID: players[idx].player.id, decision: .check))
        moveToNextState()
    }

    public mutating func fold() throws {
        guard let idx: Int = currentPlayerIndex,
              case .waitingForPlayerToAct = state else {
            throw PokerError.noCurrentPlayer
        }
        guard players[idx].isAllIn == false,
              players[idx].currentBet < maxOutstandingBet else {
            throw PokerError.cannotFoldWhenNoOutstandingBet
        }
        players[idx].status = .out
        players[idx].hasActedThisStreet = true
        log.addAction(.init(playerID: players[idx].player.id, decision: .fold))
        moveToNextState()
    }
}

// MARK: - Draw & Discard Actions
extension Round {
    public mutating func drawCards(playerID: PlayerID, discardIndices: [Int]) throws {
        guard case .waitingForDraw(let expectedID) = state,
              expectedID == playerID else {
            throw PokerError.drawNotAllowed
        }
        guard case .fiveCardDraw(var drawState) = variantRound else {
            throw PokerError.drawNotAllowed
        }
        guard var hand: [CardID] = drawState.playerCards[playerID] else {
            throw PokerError.playerNotFound
        }
        guard discardIndices.count <= 5 else {
            throw PokerError.tooManyCardsDiscarded
        }
        let sorted: [Int] = discardIndices.sorted(by: >)
        for i in sorted { hand.remove(at: i) }
        let drawCount: Int = discardIndices.count
        let newCardIDs: [CardID] = Array(drawState.deck.suffix(drawCount))
        drawState.deck.removeLast(drawCount)
        hand.append(contentsOf: newCardIDs)
        drawState.playerCards[playerID] = hand
        drawState.pendingDrawPlayerIDs.removeAll(where: { $0 == playerID })
        log.addAction(.init(playerID: playerID, decision: .draw(discardCount: discardIndices.count)))

        if drawState.pendingDrawPlayerIDs.isEmpty {
            drawState.drawComplete = true
            variantRound = .fiveCardDraw(drawState)
            street = .second
            resetPlayersForNewStreet()
            resetCurrentPlayerForNextStreet()
        } else {
            let nextID: PlayerID = drawState.pendingDrawPlayerIDs[0]
            variantRound = .fiveCardDraw(drawState)
            state = .waitingForDraw(playerID: nextID)
        }
    }

    public mutating func discardCard(playerID: PlayerID, cardIndex: Int) throws {
        guard case .waitingForDiscard(let expectedID) = state,
              expectedID == playerID else {
            throw PokerError.discardNotAllowed
        }
        guard case .pineapple(var pineState) = variantRound else {
            throw PokerError.discardNotAllowed
        }
        guard var hand: [CardID] = pineState.holeCards[playerID],
              cardIndex < hand.count else {
            throw PokerError.playerNotFound
        }
        let discardedID: CardID = hand.remove(at: cardIndex)
        pineState.holeCards[playerID] = hand
        pineState.discardedCards[playerID] = discardedID
        pineState.pendingDiscardPlayerIDs.removeAll(where: { $0 == playerID })
        log.addAction(.init(playerID: playerID, decision: .discard(cardCount: 1)))

        if pineState.pendingDiscardPlayerIDs.isEmpty {
            variantRound = .pineapple(pineState)
            resetPlayersForNewStreet()
            resetCurrentPlayerForNextStreet()
        } else {
            let nextID: PlayerID = pineState.pendingDiscardPlayerIDs[0]
            variantRound = .pineapple(pineState)
            state = .waitingForDiscard(playerID: nextID)
        }
    }
}
