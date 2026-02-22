import Foundation
import SwiftData

@Model
final class Exhibition {
    var id: UUID
    var name: String

    @Relationship(deleteRule: .nullify)
    var museum: Museum?

    @Relationship(deleteRule: .nullify)
    var artworks: [Artwork]

    init(id: UUID = UUID(), name: String = "", museum: Museum? = nil, artworks: [Artwork] = []) {
        self.id = id
        self.name = name
        self.museum = museum
        self.artworks = artworks
    }
}
