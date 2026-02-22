import SwiftUI
import SwiftData

struct MuseumDetailView: View {
    @Bindable var museum: Museum
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var showingDeleteAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Museum Info
                VStack(alignment: .leading, spacing: 8) {
                    if isEditing {
                        TextField("Museum Name", text: $museum.name)
                            .font(.title2)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(museum.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    HStack(spacing: 16) {
                        Label("\(museum.artworks.count) artworks", systemImage: "photo.artframe")
                        Label("\(museum.exhibitions.count) exhibitions", systemImage: "rectangle.stack")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Exhibitions Section
                if !museum.exhibitions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exhibitions")
                            .font(.headline)

                        ForEach(museum.exhibitions) { exhibition in
                            NavigationLink(value: exhibition) {
                                HStack {
                                    Image(systemName: "rectangle.stack.fill")
                                        .foregroundStyle(.accent)
                                    Text(exhibition.name)
                                    Spacer()
                                    Text("\(exhibition.artworks.count)")
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Artworks Grid
                if !museum.artworks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Artworks")
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(museum.artworks) { artwork in
                                NavigationLink(value: artwork) {
                                    ArtworkGridItem(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Museum")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Exhibition.self) { exhibition in
            ExhibitionDetailView(exhibition: exhibition)
        }
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
        .alert("Delete Museum", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(museum)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this museum? Artworks will not be deleted but will be unassigned.")
        }
    }
}

#Preview {
    NavigationStack {
        MuseumDetailView(museum: Museum(name: "The Metropolitan Museum of Art"))
    }
    .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
