import SwiftUI
import SwiftData

enum AddArtworkStep: Int, CaseIterable {
    case artworkPhoto
    case labelPhoto
    case review

    var title: String {
        switch self {
        case .artworkPhoto: return "Artwork Photo"
        case .labelPhoto: return "Label Photo"
        case .review: return "Review & Save"
        }
    }
}

struct AddArtworkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Museum.name) private var museums: [Museum]
    @Query(sort: \Exhibition.name) private var exhibitions: [Exhibition]

    @State private var currentStep: AddArtworkStep = .artworkPhoto
    @State private var artworkImage: UIImage?
    @State private var labelImage: UIImage?
    @State private var showingCamera = false

    @State private var title = ""
    @State private var author = ""
    @State private var background = ""
    @State private var interpretation = ""
    @State private var selectedMuseum: Museum?
    @State private var selectedExhibition: Exhibition?

    @State private var isProcessingOCR = false
    @State private var ocrError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressIndicator

                TabView(selection: $currentStep) {
                    artworkPhotoStep
                        .tag(AddArtworkStep.artworkPhoto)

                    labelPhotoStep
                        .tag(AddArtworkStep.labelPhoto)

                    reviewStep
                        .tag(AddArtworkStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationTitle("Add Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(AddArtworkStep.allCases, id: \.self) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 10, height: 10)

                    Text(step.title)
                        .font(.caption2)
                        .foregroundStyle(step == currentStep ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)

                if step != AddArtworkStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.accentColor : Color(.systemGray4))
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                }
            }
        }
        .padding()
    }

    private var artworkPhotoStep: some View {
        VStack(spacing: 20) {
            Spacer()

            if let image = artworkImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 20) {
                    Button("Retake") {
                        artworkImage = nil
                    }
                    .buttonStyle(.bordered)

                    Button("Next") {
                        currentStep = .labelPhoto
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Image(systemName: "photo.artframe")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text("Take a photo of the artwork")
                    .font(.headline)

                Text("Capture the artwork itself")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showingCamera = true
                } label: {
                    Label("Capture Artwork", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $artworkImage)
        }
    }

    private var labelPhotoStep: some View {
        VStack(spacing: 20) {
            Spacer()

            if let image = labelImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isProcessingOCR {
                    ProgressView("Extracting text...")
                } else {
                    HStack(spacing: 20) {
                        Button("Retake") {
                            labelImage = nil
                        }
                        .buttonStyle(.bordered)

                        Button("Process & Continue") {
                            processLabelOCR()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let error = ocrError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } else {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text("Take a photo of the label")
                    .font(.headline)

                Text("Capture the information label next to the artwork")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Capture Label", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Skip") {
                        currentStep = .review
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            Button("Back") {
                currentStep = .artworkPhoto
            }
            .padding(.bottom)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $labelImage)
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = artworkImage {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        if let labelImg = labelImage {
                            Image(uiImage: labelImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    LabeledTextField(label: "Title", text: $title)
                    LabeledTextField(label: "Author", text: $author)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Museum")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Museum", selection: $selectedMuseum) {
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
                        Picker("Exhibition", selection: $selectedExhibition) {
                            Text("None").tag(nil as Exhibition?)
                            ForEach(exhibitions) { exhibition in
                                Text(exhibition.name).tag(exhibition as Exhibition?)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    LabeledTextEditor(label: "Background", text: $background)
                    LabeledTextEditor(label: "Interpretation", text: $interpretation)
                }

                HStack(spacing: 20) {
                    Button("Back") {
                        currentStep = .labelPhoto
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button("Save Artwork") {
                        saveArtwork()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding(.top)
            }
            .padding()
        }
    }

    private func processLabelOCR() {
        guard let image = labelImage else { return }

        isProcessingOCR = true
        ocrError = nil

        Task {
            do {
                let textBlocks = try await OCRService.shared.recognizeText(from: image)
                let parsed = await LabelParserService.shared.parseLabel(from: textBlocks)

                await MainActor.run {
                    if title.isEmpty { title = parsed.title }
                    if author.isEmpty { author = parsed.author }
                    if background.isEmpty { background = parsed.background }
                    if interpretation.isEmpty { interpretation = parsed.interpretation }

                    isProcessingOCR = false
                    currentStep = .review
                }
            } catch {
                await MainActor.run {
                    ocrError = "Failed to extract text: \(error.localizedDescription)"
                    isProcessingOCR = false
                }
            }
        }
    }

    private func saveArtwork() {
        let artwork = Artwork(
            artworkImageData: artworkImage?.jpegData(compressionQuality: 0.8),
            labelImageData: labelImage?.jpegData(compressionQuality: 0.8),
            title: title,
            author: author,
            background: background,
            interpretation: interpretation,
            museum: selectedMuseum,
            exhibition: selectedExhibition
        )

        modelContext.insert(artwork)
        dismiss()
    }
}

#Preview {
    AddArtworkView()
        .modelContainer(for: [Artwork.self, Museum.self, Exhibition.self], inMemory: true)
}
