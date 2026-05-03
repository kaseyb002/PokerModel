import Foundation

public enum PokerError: Error, Sendable {
    case insufficientPlayers
    case tooManyPlayers
    case insufficientBet
    case insufficientRaise
    case cannotFoldWhenNoOutstandingBet
    case cannotCheckWhenOutstandingBet
    case noCurrentPlayer
    case playerNotFound
    case invalidAction
    case roundAlreadyComplete
    case drawNotAllowed
    case discardNotAllowed
    case tooManyCardsDiscarded
    case bringInAlreadyPosted
    case blindAlreadyPosted
}
