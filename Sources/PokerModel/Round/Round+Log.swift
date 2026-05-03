import Foundation

extension Round {
    public struct Log: Equatable, Codable, Sendable {
        public var actions: [PlayerAction] = []

        public struct PlayerAction: Equatable, Codable, Sendable {
            public let playerID: PlayerID
            public let decision: Decision
            public let timestamp: Date

            public enum CodingKeys: String, CodingKey {
                case playerID = "playerId"
                case decision, timestamp
            }

            public enum Decision: Equatable, Codable, Sendable {
                case postSmallBlind(amount: Decimal)
                case postBigBlind(amount: Decimal)
                case postAnte(amount: Decimal)
                case postBringIn(amount: Decimal)
                case fold
                case check
                case bet(amount: Decimal, isAllIn: Bool)
                case call(amount: Decimal, isAllIn: Bool)
                case raise(amount: Decimal, isAllIn: Bool)
                case draw(discardCount: Int)
                case discard(cardCount: Int)
            }

            public init(
                playerID: PlayerID,
                decision: Decision,
                timestamp: Date = .init()
            ) {
                self.playerID = playerID
                self.decision = decision
                self.timestamp = timestamp
            }
        }

        public init(actions: [PlayerAction] = []) {
            self.actions = actions
        }

        public mutating func addAction(_ action: PlayerAction) {
            actions.append(action)
            if actions.count > Round.maxLogActions {
                actions.removeFirst(actions.count - Round.maxLogActions)
            }
        }
    }
}
