import Foundation

public typealias PlayerID = String

public struct Player: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var chipCount: Decimal
    public var imageURL: URL?

    public enum CodingKeys: String, CodingKey {
        case id, name, chipCount
        case imageURL = "imageUrl"
    }

    public init(
        id: PlayerID,
        name: String,
        chipCount: Decimal,
        imageURL: URL?
    ) {
        self.id = id
        self.name = name
        self.chipCount = chipCount
        self.imageURL = imageURL
    }
}
