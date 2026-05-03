import Foundation

public final class Lorem: Sendable {
    public static var firstName: String {
        firstNames.randomElement()!
    }

    private static let firstNames: [String] = [
        "Judith", "Angelo", "Kerry", "Lorenzo", "Justice", "Doris",
        "Penny", "Mohammed", "Harvey", "Hudson", "Brendan", "Denis",
        "Sadie", "Casey", "Angela", "Katherine", "Abel", "Luis",
        "Roberto", "Earl", "Jackie", "Sienna", "Jean", "Connor",
        "Ruby", "Alfredo", "Bonnie", "Gordon", "John", "Samuel",
        "Carmen", "Maggie", "Quinn", "Isabel", "Emma", "Byron",
        "Courtney", "George", "Preston", "Caleb", "Kenneth", "Arturo",
        "Skye", "Ana", "Pete", "Allen", "Eric", "Kelly", "Joey",
        "Katie", "Alexis", "Eliza", "Bryce", "Eli", "Janet",
        "Carla", "Michelle", "Reid", "Beau", "Rafael", "Clinton",
        "Angelina", "Neil", "Omar", "Abigail", "Phil", "Andre",
        "Billy", "Patrick", "Antonio", "Jamie", "Sydney", "Harrison",
        "Ian", "Tracy", "Shawn"
    ]
}
