import SwiftUI
import SwiftData

struct MuseumListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Museum.name) private var museums: [Museum]
    @State private var showingAddMuseum = false
    @State private var newMuseumName = ""

    var body: some View {
        NavigationStack {
            Group {
                if museums.isEmpty {
                    ContentUnavailableView {
                        Label("No Museums", systemImage: "building.columns")
                    } description: {
                        Text("Add museums to organize your artworks")
                    } actions: {
                        Button("Add Museum") {
                            showingAddMuseum = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(museums) { museum in
                            NavigationLink(value: museum) {
                                MuseumRow(museum: museum)
                            }
                        }
                        .onDelete(perform: deleteMuseums)
                    }
                }
            }
            .navigationTitle("Museums")
            .navigationDestination(for: Museum.self) { museum in
                MuseumDetailView(museum: museum)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMuseum = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Add Museum", isPresented: $showingAddMuseum) {
                TextField("Museum name", text: $newMuseumName)
                Button("Cancel", role: .cancel) {
                    newMuseumName = ""
                }
                Button("Add") {
                    addMuseum()
                }
            } message: {
                Text("Enter the name of the museum")
            }
        }
    }

    private func addMuseum() {
        guard !newMuseumName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let museum = Museum(name: newMuseumName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(museum)
        newMuseumName = ""
    }

    private func deleteMuseums(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(museums[index])
        }
    }
}

struct MuseumRow: View {
    let museum: Museum

    var body: some View {
        HStack {
            Image(systemName: "building.columns.fill")
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(museum.name)
                    .font(.headline)

                Text("\(museum.artworks.count) artwork\(museum.artworks.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MuseumListView()
        .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
