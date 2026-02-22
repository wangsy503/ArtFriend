import SwiftUI
import SwiftData

struct ArtworkListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Artwork.createdAt, order: .reverse) private var artworks: [Artwork]
    @Query(sort: \Museum.name) private var museums: [Museum]
    @Query(sort: \Exhibition.name) private var exhibitions: [Exhibition]

    @State private var selectedMuseum: Museum?
    @State private var selectedExhibition: Exhibition?
    @State private var showingAddArtwork = false
    @State private var searchText = ""

    private var filteredArtworks: [Artwork] {
        var result = artworks

        if let museum = selectedMuseum {
            result = result.filter { $0.museum?.id == museum.id }
        }

        if let exhibition = selectedExhibition {
            result = result.filter { $0.exhibition?.id == exhibition.id }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !museums.isEmpty || !exhibitions.isEmpty {
                    VStack(spacing: 8) {
                        if !museums.isEmpty {
                            FilterChipGroup(
                                items: museums,
                                titleKeyPath: \.name,
                                selection: $selectedMuseum,
                                allTitle: "All Museums"
                            )
                        }

                        if !exhibitions.isEmpty {
                            FilterChipGroup(
                                items: exhibitions,
                                titleKeyPath: \.name,
                                selection: $selectedExhibition,
                                allTitle: "All Exhibitions"
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }

                if filteredArtworks.isEmpty {
                    ContentUnavailableView {
                        Label("No Artworks", systemImage: "photo.artframe")
                    } description: {
                        Text("Add your first artwork by tapping the + button")
                    } actions: {
                        Button("Add Artwork") {
                            showingAddArtwork = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredArtworks) { artwork in
                                NavigationLink(value: artwork) {
                                    ArtworkGridItem(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Artworks")
            .navigationDestination(for: Artwork.self) { artwork in
                ArtworkDetailView(artwork: artwork)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddArtwork = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search artworks")
            .sheet(isPresented: $showingAddArtwork) {
                AddArtworkView()
            }
        }
    }
}

struct ArtworkGridItem: View {
    let artwork: Artwork

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let imageData = artwork.artworkImageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "photo.artframe")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if !artwork.author.isEmpty {
                    Text(artwork.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    ArtworkListView()
        .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
