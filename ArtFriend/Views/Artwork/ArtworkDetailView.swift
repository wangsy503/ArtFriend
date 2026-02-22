import SwiftUI
import SwiftData

struct ArtworkDetailView: View {
    @Bindable var artwork: Artwork
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Museum.name) private var museums: [Museum]
    @Query(sort: \Exhibition.name) private var exhibitions: [Exhibition]

    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingArtworkImage = false
    @State private var showingLabelImage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Artwork Image
                imageSection(
                    title: "Artwork",
                    imageData: artwork.artworkImageData,
                    showingFullscreen: $showingArtworkImage
                )

                // Label Image
                if artwork.labelImageData != nil {
                    imageSection(
                        title: "Label",
                        imageData: artwork.labelImageData,
                        showingFullscreen: $showingLabelImage
                    )
                }

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    if isEditing {
                        editableDetails
                    } else {
                        readOnlyDetails
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(artwork.title.isEmpty ? "Artwork" : artwork.title)
        .navigationBarTitleDisplayMode(.inline)
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
        .alert("Delete Artwork", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(artwork)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this artwork? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showingArtworkImage) {
            FullscreenImageView(imageData: artwork.artworkImageData)
        }
        .fullScreenCover(isPresented: $showingLabelImage) {
            FullscreenImageView(imageData: artwork.labelImageData)
        }
    }

    @ViewBuilder
    private func imageSection(title: String, imageData: Data?, showingFullscreen: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            if let data = imageData, let image = UIImage(data: data) {
                Button {
                    showingFullscreen.wrappedValue = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }

    @ViewBuilder
    private var editableDetails: some View {
        Group {
            LabeledTextField(label: "Title", text: $artwork.title)
            LabeledTextField(label: "Author", text: $artwork.author)

            VStack(alignment: .leading, spacing: 4) {
                Text("Museum")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Museum", selection: $artwork.museum) {
                    Text("None").tag(nil as Museum?)
                    ForEach(museums) { museum in
                        Text(museum.name).tag(museum as Museum?)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Exhibition")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Exhibition", selection: $artwork.exhibition) {
                    Text("None").tag(nil as Exhibition?)
                    ForEach(exhibitions) { exhibition in
                        Text(exhibition.name).tag(exhibition as Exhibition?)
                    }
                }
                .pickerStyle(.menu)
            }

            LabeledTextEditor(label: "Background", text: $artwork.background)
            LabeledTextEditor(label: "Interpretation", text: $artwork.interpretation)
        }
    }

    @ViewBuilder
    private var readOnlyDetails: some View {
        Group {
            if !artwork.title.isEmpty {
                DetailRow(label: "Title", value: artwork.title)
            }

            if !artwork.author.isEmpty {
                DetailRow(label: "Author", value: artwork.author)
            }

            if let museum = artwork.museum {
                DetailRow(label: "Museum", value: museum.name)
            }

            if let exhibition = artwork.exhibition {
                DetailRow(label: "Exhibition", value: exhibition.name)
            }

            if !artwork.background.isEmpty {
                DetailRow(label: "Background", value: artwork.background)
            }

            if !artwork.interpretation.isEmpty {
                DetailRow(label: "Interpretation", value: artwork.interpretation)
            }

            DetailRow(label: "Added", value: artwork.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

struct LabeledTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct LabeledTextEditor: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(4)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct FullscreenImageView: View {
    let imageData: Data?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let data = imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ContentUnavailableView("No Image", systemImage: "photo")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArtworkDetailView(artwork: Artwork(
            title: "Starry Night",
            author: "Vincent van Gogh",
            background: "Painted in June 1889, it depicts the view from the east-facing window of his asylum room.",
            interpretation: "The painting represents Van Gogh's emotional turmoil and his fascination with the night sky."
        ))
    }
    .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
