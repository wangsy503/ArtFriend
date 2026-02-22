import SwiftUI
import SwiftData

struct ExhibitionDetailView: View {
    @Bindable var exhibition: Exhibition
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Museum.name) private var museums: [Museum]

    @State private var isEditing = false
    @State private var showingDeleteAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Exhibition Info
                VStack(alignment: .leading, spacing: 8) {
                    if isEditing {
                        TextField("Exhibition Name", text: $exhibition.name)
                            .font(.title2)
                            .textFieldStyle(.roundedBorder)

                        Picker("Museum", selection: $exhibition.museum) {
                            Text("None").tag(nil as Museum?)
                            ForEach(museums) { museum in
                                Text(museum.name).tag(museum as Museum?)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text(exhibition.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let museum = exhibition.museum {
                            Label(museum.name, systemImage: "building.columns")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Label("\(exhibition.artworks.count) artworks", systemImage: "photo.artframe")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Artworks Grid
                if !exhibition.artworks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Artworks")
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(exhibition.artworks) { artwork in
                                NavigationLink(value: artwork) {
                                    ArtworkGridItem(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Artworks", systemImage: "photo.artframe")
                    } description: {
                        Text("Artworks added to this exhibition will appear here")
                    }
                    .frame(minHeight: 200)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Exhibition")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Artwork.self) { artwork in
            ArtworkDetailView(artwork: artwork)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
            }

            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Exhibition", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(exhibition)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this exhibition? Artworks will not be deleted but will be unassigned.")
        }
    }
}

#Preview {
    NavigationStack {
        ExhibitionDetailView(exhibition: Exhibition(name: "Impressionist Masters"))
    }
    .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
