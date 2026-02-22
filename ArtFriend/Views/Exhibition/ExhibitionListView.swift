import SwiftUI
import SwiftData

struct ExhibitionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exhibition.name) private var exhibitions: [Exhibition]
    @Query(sort: \Museum.name) private var museums: [Museum]
    @State private var showingAddExhibition = false
    @State private var newExhibitionName = ""
    @State private var selectedMuseum: Museum?

    var body: some View {
        NavigationStack {
            Group {
                if exhibitions.isEmpty {
                    ContentUnavailableView {
                        Label("No Exhibitions", systemImage: "rectangle.stack")
                    } description: {
                        Text("Add exhibitions to organize your artworks")
                    } actions: {
                        Button("Add Exhibition") {
                            showingAddExhibition = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(exhibitions) { exhibition in
                            NavigationLink(value: exhibition) {
                                ExhibitionRow(exhibition: exhibition)
                            }
                        }
                        .onDelete(perform: deleteExhibitions)
                    }
                }
            }
            .navigationTitle("Exhibitions")
            .navigationDestination(for: Exhibition.self) { exhibition in
                ExhibitionDetailView(exhibition: exhibition)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExhibition = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExhibition) {
                AddExhibitionSheet(
                    name: $newExhibitionName,
                    selectedMuseum: $selectedMuseum,
                    museums: museums
                ) {
                    addExhibition()
                }
            }
        }
    }

    private func addExhibition() {
        guard !newExhibitionName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let exhibition = Exhibition(
            name: newExhibitionName.trimmingCharacters(in: .whitespaces),
            museum: selectedMuseum
        )
        modelContext.insert(exhibition)
        newExhibitionName = ""
        selectedMuseum = nil
    }

    private func deleteExhibitions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(exhibitions[index])
        }
    }
}

struct ExhibitionRow: View {
    let exhibition: Exhibition

    var body: some View {
        HStack {
            Image(systemName: "rectangle.stack.fill")
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(exhibition.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let museum = exhibition.museum {
                        Text(museum.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(exhibition.artworks.count) artwork\(exhibition.artworks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddExhibitionSheet: View {
    @Binding var name: String
    @Binding var selectedMuseum: Museum?
    let museums: [Museum]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exhibition name", text: $name)
                }

                Section("Museum (Optional)") {
                    Picker("Museum", selection: $selectedMuseum) {
                        Text("None").tag(nil as Museum?)
                        ForEach(museums) { museum in
                            Text(museum.name).tag(museum as Museum?)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Add Exhibition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        name = ""
                        selectedMuseum = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ExhibitionListView()
        .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
