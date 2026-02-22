import Foundation
import SwiftData

@Model
final class Museum {
    var id: UUID
    var name: String

    @Relationship(deleteRule: .nullify)
    var artworks: [Artwork]

    @Relationship(deleteRule: .nullify, inverse: \Exhibition.museum)
    var exhibitions: [Exhibition]

    init(id: UUID = UUID(), name: String = "", artworks: [Artwork] = [], exhibitions: [Exhibition] = []) {
        self.id = id
        self.name = name
        self.artworks = artworks
        self.exhibitions = exhibitions
    }
}
