# Morse Trainer iOS

A SwiftUI app that fetches random Wikipedia articles and plays the first sentence as Morse code. The article is deliberately hidden during transmission so you can practise decoding before seeing the answer.

## Features

- Fetches a random Wikipedia article and plays it as Morse code via the device speaker
- **Test mode** — article content hidden until you tap Reveal
- **Learn mode** — decoded characters appear in real time as each one is transmitted
- Adjustable speed from 50–150 CPM, changeable during playback
- Tap "Stop sending" at any time to halt playback and go straight to Reveal

## Requirements

- iOS 16.0+
- Xcode 15+
- Swift 5.9+

## Getting Started

1. Clone the repo:
   ```bash
   git clone git@github.com:mamorrow1957/morsetrainerios.git
   ```
2. Open `MorseTraineriOS.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run (`⌘R`)

No third-party dependencies — uses only Apple frameworks (`SwiftUI`, `AVFoundation`, `Foundation`).

## How It Works

1. Tap **"Find an article"** — the app fetches a random Wikipedia article
2. The first meaningful sentence is extracted and played as Morse code
3. Adjust the **Speed** slider (50–150 CPM) at any time during playback
4. Tap **"Stop sending"** to stop early, or wait for playback to finish
5. Tap **"Reveal"** to see the article title, sentence, and source link

## Project Structure

```
MorseTraineriOS/
├── MorseTrainerIOSApp.swift      # App entry point
├── ContentView.swift             # Root view
├── ViewModels/
│   └── MorseViewModel.swift      # App state and business logic
├── Models/
│   └── ArticleModel.swift        # Wikipedia article data model
└── Services/
    ├── WikipediaService.swift    # Article fetching
    ├── MorseEngine.swift         # Morse code playback engine
    └── SentenceExtractor.swift   # Sentence extraction logic
```

## Attribution

Vibe coded in Feb–Mar 2026 by Michael Morrow
