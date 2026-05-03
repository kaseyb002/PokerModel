import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = Lorem.firstName,
        chipCount: Decimal = .init(integerLiteral: .random(in: 1...20) * 100),
        imageURL: URL? = .randomImageURL
    ) -> Player {
        .init(id: id, name: name, chipCount: chipCount, imageURL: imageURL)
    }
}

extension RoundPlayer {
    public static func fake(
        player: Player = .fake(),
        status: Status = .in
    ) -> RoundPlayer {
        .init(player: player, status: status)
    }
}
