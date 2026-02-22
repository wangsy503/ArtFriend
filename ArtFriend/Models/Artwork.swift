import Foundation
import SwiftData

@Model
final class Artwork {
    var id: UUID
    @Attribute(.externalStorage) var artworkImageData: Data?
    @Attribute(.externalStorage) var labelImageData: Data?
    var title: String
    var author: String
    var background: String
    var interpretation: String
    var createdAt: Date

    @Relationship(inverse: \Museum.artworks)
    var museum: Museum?

    @Relationship(inverse: \Exhibition.artworks)
    var exhibition: Exhibition?

    init(
        id: UUID = UUID(),
        artworkImageData: Data? = nil,
        labelImageData: Data? = nil,
        title: String = "",
        author: String = "",
        background: String = "",
        interpretation: String = "",
        createdAt: Date = Date(),
        museum: Museum? = nil,
        exhibition: Exhibition? = nil
    ) {
        self.id = id
        self.artworkImageData = artworkImageData
        self.labelImageData = labelImageData
        self.title = title
        self.author = author
        self.background = background
        self.interpretation = interpretation
        self.createdAt = createdAt
        self.museum = museum
        self.exhibition = exhibition
    }
}
