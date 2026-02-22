# ArtFriend

An iOS app that helps museum visitors capture and organize artwork information using photos and OCR text extraction.

## Features

- **Capture Artworks**: Take photos of artworks and their information labels
- **OCR Text Extraction**: Automatically extract text from labels using Apple's Vision framework
- **Smart Label Parsing**: Parse extracted text to identify title, author, background, and interpretation
  - Uses Apple Intelligence (FoundationModels) on iOS 18.1+ for intelligent parsing
  - Falls back to heuristic-based parsing on older devices
- **Organize by Museum & Exhibition**: Tag artworks with museum and exhibition information
- **Filter & Browse**: Search and filter your collection by museum or exhibition

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- For Apple Intelligence features: iOS 18.1+ with compatible device (A17 Pro or M-series chip)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/wangsy503/ArtFriend.git
   ```

2. Open `ArtFriend.xcodeproj` in Xcode

3. Build and run on your device or simulator

## Usage

### Adding an Artwork

1. Tap the **+** button on the Artworks tab
2. **Step 1**: Take a photo of the artwork
3. **Step 2**: Take a photo of the information label
4. **Step 3**: Review the automatically extracted information and make any corrections
5. Optionally assign a museum and exhibition
6. Save

### Managing Museums & Exhibitions

- Use the **Museums** tab to create and manage museums
- Use the **Exhibitions** tab to create exhibitions (optionally linked to a museum)
- Artworks can be filtered by museum or exhibition on the main Artworks tab

## Technical Architecture

```
ArtFriend/
├── Models/
│   ├── Artwork.swift       # Core artwork data model (SwiftData)
│   ├── Museum.swift        # Museum model with relationships
│   └── Exhibition.swift    # Exhibition model with relationships
├── Services/
│   ├── OCRService.swift    # Vision framework text recognition
│   └── LabelParserService.swift  # AI/heuristic label parsing
├── Views/
│   ├── Artwork/            # Artwork list, detail, and add views
│   ├── Museum/             # Museum management views
│   └── Exhibition/         # Exhibition management views
└── Components/
    ├── CameraView.swift    # Camera capture component
    ├── ImagePicker.swift   # Photo library picker
    └── FilterChip.swift    # Filter UI components
```

## Tech Stack

- **UI**: SwiftUI
- **Persistence**: SwiftData
- **OCR**: Vision framework (VNRecognizeTextRequest)
- **Text Parsing**: NaturalLanguage framework + FoundationModels (iOS 18.1+)
- **Camera**: PhotosUI + AVFoundation

## Label Parsing

The app intelligently parses museum labels to extract:

| Field | Description |
|-------|-------------|
| **Title** | Artwork title (year stripped if present) |
| **Author** | Artist name (dates and nationality removed) |
| **Background** | Historical context or description |
| **Interpretation** | How to understand or appreciate the artwork |

Supported label formats:
- Author with dates: `Vincent van Gogh (1853-1890)`
- Title first: `Mona Lisa` followed by author
- Birth/death locations: `Enkhuizen 1625-1654 Amsterdam`
- Contemporary artists: `Born 1929, Japan`

## License

MIT License

## Acknowledgments

- Built with assistance from Claude (Anthropic)
- Uses Apple's Vision and NaturalLanguage frameworks
