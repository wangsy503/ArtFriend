import SwiftUI
import AVFoundation

struct CameraView: View {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    @State private var cameraAvailable = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()

                    HStack(spacing: 20) {
                        Button("Retake") {
                            capturedImage = nil
                        }
                        .buttonStyle(.bordered)

                        Button("Use Photo") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Spacer()

                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("Capture or select a photo")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    VStack(spacing: 12) {
                        if cameraAvailable {
                            Button {
                                showingImagePicker = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }

                        PhotoLibraryPickerButton(selectedImage: $capturedImage)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Capture Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        capturedImage = nil
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $capturedImage, sourceType: .camera)
                    .ignoresSafeArea()
            }
            .onAppear {
                checkCameraAvailability()
            }
        }
    }

    private func checkCameraAvailability() {
        cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}

struct PhotoLibraryPickerButton: View {
    @Binding var selectedImage: UIImage?
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .sheet(isPresented: $showingPicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    CameraView(capturedImage: .constant(nil))
}
