import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            ArtworkListView()
                .tabItem {
                    Label("Artworks", systemImage: "photo.artframe")
                }

            MuseumListView()
                .tabItem {
                    Label("Museums", systemImage: "building.columns")
                }

            ExhibitionListView()
                .tabItem {
                    Label("Exhibitions", systemImage: "rectangle.stack")
                }

            LabelParserTestView()
                .tabItem {
                    Label("Tests", systemImage: "checklist")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
