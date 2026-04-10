# Morse Trainer iOS — Project Specifications

---

## 1. Project Overview

**Morse Trainer iOS** is a single-screen SwiftUI application that fetches random Wikipedia articles and plays the first sentence as Morse code via the device speaker. The article content is deliberately withheld during transmission and only revealed afterwards, so the user can practise decoding the code before seeing the answer. The user can adjust playback speed in real time, even while code is being sent.

**App display name (home screen icon label):** Morse Trainer (`INFOPLIST_KEY_CFBundleDisplayName`)

**Platform:** iOS 16.0+
**Language:** Swift 5.9+
**UI Framework:** SwiftUI
**Audio Framework:** AVFoundation (`AVAudioEngine`, `AVAudioPlayerNode`)

---

## 2. Project Structure

```
MorseTraineriOS/
├── MorseTraineriOS.xcodeproj
├── MorseTraineriOS/
│   ├── MorseTrainerIOSApp.swift      # App entry point
│   ├── ContentView.swift             # Root view
│   ├── Info.plist                    # App configuration (fonts, orientations, etc.)
│   ├── ViewModels/
│   │   └── MorseViewModel.swift      # App state and business logic
│   ├── Models/
│   │   └── ArticleModel.swift        # Wikipedia article data model
│   ├── Services/
│   │   ├── WikipediaService.swift    # Article fetching
│   │   ├── MorseEngine.swift         # Morse code playback engine
│   │   └── SentenceExtractor.swift   # Sentence extraction logic
│   ├── Fonts/
│   │   └── 1942.ttf                  # 1942 Report custom font (Johan Holmdahl, freeware)
│   └── Assets.xcassets
└── MorseTraineriOSTests/
    └── MorseTraineriOSTests.swift    # XCTest unit test suite
```

---

## 3. Screen Layout

### 3.1 Overall Structure

The screen is a single `VStack` divided into three regions that together fill the entire display:

| Region | SwiftUI Element | Background Color |
|--------|----------------|-----------------|
| Header | `VStack` / `Text` | Very dark grey (`#1a1a1a`) |
| Main Content | `VStack` (fills remaining space) | Very dark grey (`#1a1a1a`) |
| Footer | `VStack` / `Text` | Very dark grey (`#1a1a1a`) |

The screen background must be uniformly dark grey with no visible dividers between regions. The layout must respect safe area insets on all device sizes.

### 3.2 Header

- Contains the app title: **"Morse Trainer"** with a typewriter character-by-character animation on **first launch only**, accompanied by mechanical click sounds. On subsequent appearances (e.g. device rotation), the full title is displayed immediately with no animation or sounds.
- Text color: `#e0e0e0` (very light grey)
- Font: **1942 Report** (`1942report`) custom font, auto-scaled to match the width of the text box using `minimumScaleFactor`
- Centered horizontally with `.padding(.horizontal, 20)` to align with the text box edges

### 3.3 Footer

- Contains the attribution string: **"vibe coded in Feb–Apr 2026 by Michael Morrow"**
- Text color: `#ff4d00`
- Centered, small font

### 3.4 Main Content Area

The main content region holds the text box, the Learn/Test mode picker, the speed control, and the button. It uses a `GeometryReader` wrapping a `VStack`, with all spacing and sizing expressed as proportions of the available height so the layout scales correctly across all iPhone sizes:

| Element | Size |
|---------|------|
| Text box height | 34% of available height |
| Gap between text box and controls | 3% of available height |
| Gap between controls and button | 3% of available height |
| Bottom spacer (pushes content above center) | 19% of available height |

---

## 4. Text Box

| Property | Value |
|----------|-------|
| Background | Very light grey (`#e8e8e8`) |
| Text color | Black |
| Width | Full width with horizontal padding (`.frame(maxWidth: .infinity)`) |
| Height | 34% of the main content area's available height (proportional, via `GeometryReader`) |
| Corner radius | 8 pt |
| Font size | Body — large enough to comfortably display several rows of text |
| Placeholder text | **"Press the button …"** — shown when content is empty |
| Scrolling | Content is wrapped in a `ScrollView`; text scrolls vertically if it overflows |

The text box is read-only (display only). It must be capable of rendering a tappable hyperlink on its third line when in Reveal state (see §8 — Article Display). The Source line is rendered as a composed `Text` view (bold `"Source: "` + blue URL text) with an `.onTapGesture` that calls `UIApplication.shared.open(url)` — **not** a SwiftUI `Link`, as `Link` inside a `ScrollView` causes alignment issues.

### 4.1 Text Box States

| State | Content |
|-------|---------|
| Idle (initial launch or after Reveal) | Placeholder text: **"Press the button …"** |
| Sending (Test mode) | **"Sending …"** |
| Sending (Learn mode) | Accumulated decoded characters, updated in real time |
| Finished (Test mode) | **"Send complete…"** |
| Finished (Learn mode) | Decoded sentence remains visible — not replaced with "Send complete…" |
| Stopped | **"Stopped …"** |
| Error | **"Error fetching article: \<reason\>"** in red |
| Reveal | The three article lines (Title, Sentence, Source) as described in §8 |

---

## 5. Learn/Test Mode Picker

A segmented `Picker` placed to the **left of the speed slider**, in an `HStack` within the controls area.

| Property | Value |
|----------|-------|
| Style | Segmented picker (`PickerStyle.segmented`) |
| Width | Fixed at 120 pt |
| Choices | **"Learn"** and **"Test"** |
| Default | **"Test"** |
| Selected segment tint | `#ff4d00` (orange) — always, including during playback |
| Non-selected segment background | Dark grey (`UIColor(white: 0.25, alpha: 1)`) with white text |
| Label font | `.subheadline` |

Appearance is set globally via `UISegmentedControl.appearance()` in the app entry point so the colors remain consistent at all times.

The picker is **never visually disabled**. Instead, mode changes triggered during active playback are silently rejected in `MorseViewModel` (the `mode` property's `didSet` restores the previous value if `appState == .sending` or `.loading`). This prevents the selected segment tint from changing colour during playback.

### 5.1 Test Mode (default)

When set to **Test**, article content is hidden during Morse playback and revealed only when the user taps "Reveal" (or "Stop sending").

### 5.2 Learn Mode

When set to **Learn**, each character is revealed to the user **as its Morse code is transmitted** at the currently selected speed:

- The text box **starts empty** when playback begins (no "Sending …" message in Learn mode).
- Decoded characters are appended to the text box in real time, in their **original sentence case** (not uppercased).
- Each character is appended **as its first Morse symbol (dit or dah) begins playing**.
- Word spaces are appended at the start of the inter-word gap, triggered by the same `onCharacterStart` callback used for letters.
- When playback completes naturally, the decoded sentence **remains in the text box** (it is not replaced with "Send complete…").
- **Stop and Reveal** behave identically to Test mode.

---

## 6. Controls Area

The controls area sits below the text box, grouped in a `VStack`, horizontally centered.

### 6.1 Speed Slider

| Property | Value |
|----------|-------|
| SwiftUI element | `Slider` |
| Minimum | 10 WPM (= 50 CPM) |
| Maximum | 50 WPM (= 250 CPM) |
| Default | 30 WPM (= 150 CPM) |
| Step | 1 WPM |
| Selected (filled) track tint | `#ff4d00` (set via `.tint(accent)`) |
| Unselected (remaining) track color | Dark grey (`UIColor(white: 0.25, alpha: 1)`) — set via `UISlider.appearance().maximumTrackTintColor` to match the mode picker non-selected background |
| Label color | `#ff4d00` |
| Label font | `.subheadline` |
| Live readout | A `Text` view above the slider displaying **"Speed: \<value\> WPM"** |

Speed is stored as WPM and converted to CPM (×5) when passed to `MorseEngine`. The slider value is readable at any time, including during playback. Changing the slider mid-transmission takes effect on the next Morse symbol (see §9.3).

### 6.2 Button

| Property | Value |
|----------|-------|
| Width | ~60% of screen width |
| Background | Very light grey (`#e8e8e8`) |
| Text color | Black |
| Font size | Large enough to fill the button visually |
| Corner radius | 8 pt |
| Horizontal position | Centered |

The button cycles through four states:

| State | Label | Action on tap |
|-------|-------|---------------|
| **Idle** | **"Find an article"** | Fetch article, begin Morse playback, enter Sending state |
| **Sending** | **"Stop sending"** | Immediately halt playback and enter Reveal state |
| **Reveal** | **"Reveal"** | Populate text box with article content (§8), enter Idle state |
| *(loading)* | **"Loading…"** | Disabled — fetch in progress |

State transition rules:
1. On launch the button is in **Idle** state.
2. Tapping **"Find an article"** fetches the article (button shows "Loading…" and is disabled), then begins Morse playback and switches to **Sending**.
3. When Morse playback completes naturally, the text box shows "Send complete…" and the button advances to **Reveal**.
4. Tapping **"Stop sending"** immediately halts playback, shows "Stopped …", and advances to **Reveal**.
5. Tapping **"Reveal"** populates the text box with the three article lines (§8) and returns to **Idle**.
6. The button must **never** show **"Stop sending"** when no Morse playback is in progress.

---

## 7. Wikipedia Article Fetching

Implemented in `WikipediaService.swift` using `URLSession`.

When "Find an article" is tapped:

1. A **random English Wikipedia article** is fetched via:
   ```
   https://en.wikipedia.org/api/rest_v1/page/random/summary
   ```
2. The article title, extracted sentence, and URL are decoded from the JSON response and stored in `ArticleModel`.
3. Morse playback of the extracted sentence begins immediately after a successful fetch.
4. Article content is **not shown** until the user taps "Reveal".

The fetch must have a **10-second timeout** (`URLRequest.timeoutInterval = 10`). On failure:

- Display **"Error fetching article: \<reason\>"** in red in the text box.
- Return the button to **"Find an article"** (Idle state).
- Set `appState = .idle` in the view model.

---

## 8. Article Display

When the user taps **"Reveal"** (or **"Stop sending"**, which triggers Reveal immediately), the text box is populated with exactly three lines:

| Line | Format |
|------|--------|
| Line 1 | `Title: <article title>` |
| Line 2 | `Sentence: <first complete sentence from the article content>` |
| Line 3 | `Source: <article URL>` — rendered as tappable blue text that opens in Safari via `UIApplication.shared.open` |

The Source URL must open in the device's default browser. Implemented as a composed `Text` view with `.onTapGesture` rather than a SwiftUI `Link` to avoid alignment issues inside `ScrollView`.

### 8.1 Sentence Extraction Rules

Implemented in `SentenceExtractor.swift`.

- The target sentence is the **first complete sentence** found in the article's `extract` field from the Wikipedia API response.
- A sentence ends with `.`, `!`, or `?` followed by a space or end-of-string.
- Sentences must be **longer than 5 words**.
- **Abbreviations must not be treated as sentence terminators.** Excluded: titles (`Dr.`, `Mr.`, `Mrs.`, `Ms.`, `Prof.`), common terms (`vs.`, `etc.`, `Jr.`, `Sr.`, `Fig.`, `No.`, `St.`, `Ave.`, `Blvd.`, `Dept.`, `Est.`, `Approx.`), corporate suffixes (`Inc.`, `Ltd.`, `Corp.`), honorifics (`Gov.`, `Gen.`, `Col.`, `Sgt.`, `Cpl.`, `Pvt.`, `Rep.`, `Sen.`, `Rev.`), months (`Jan.`–`Dec.`), days (`Mon.`–`Sun.`), academic/Latin abbreviations (`Vol.`, `pp.`, `ed.`, `al.`, `ie.`, `eg.`, `op.`, `ca.`, `cf.`, `et.`), and single capital-letter initials (e.g. `J.`).
- Strip any residual wiki markup, citation brackets (e.g., `[1]`), or HTML tags before display.
- **Fallback:** If no qualifying sentence is found, use the first 250 characters of the cleaned text.

---

## 9. Morse Code Playback

Implemented in `MorseEngine.swift`.

### 9.1 Timing Basis

Morse timing is derived from the **CPM** value on the speed slider:

```
unitSeconds = 60.0 / (Double(cpm) * 8.0)
```

*(Consistent with the PARIS standard — approximately 6 units per average character.)*

### 9.2 Element Durations

| Element | Duration |
|---------|----------|
| Dot | 1 unit |
| Dash | 3 units |
| Intra-character gap (between dot/dash) | 1 unit |
| Inter-character gap (between letters) | 3 units |
| Inter-word gap | 7 units (halved to 3.5 units per original spec note — see below) |

> **Note:** Inter-word gaps are shortened to half the standard 7-unit word space for a faster, more compressed playback cadence (matching the web version behaviour).

### 9.3 Real-Time Speed Adjustment

- The CPM value is sampled **per symbol** (each dot, dash, or gap).
- Moving the slider during transmission takes effect on the next scheduled symbol without interrupting the current one.
- No audio glitches or gaps should result from a mid-playback speed change.

### 9.4 Audio Implementation

- Use `AVAudioEngine` with an `AVAudioPlayerNode` and programmatically generated PCM audio buffers.
- Configure `AVAudioSession` with category `.playback` and mode `.default` so audio plays even when the device is on silent (ringer switch off).
- PCM buffer format: **44100 Hz, mono, non-interleaved float32** (`AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)`). This format must be used for both the node connection and all buffers — a mismatch causes a crash.
- Use the Swift async `scheduleBuffer` API (`await node.scheduleBuffer(buffer)`) rather than the completion-handler variant.
- Tone frequency: **650 Hz** (standard Morse sidetone).
- No other sounds are played before or between Morse characters.
- If audio setup fails, playback falls back to a timed delay (silent mode) so the rest of the UI still functions.
- The `AddInstanceForFactory` CoreAudio message that appears in the simulator is a known harmless warning; it does not appear on physical devices.

### 9.5 Playback Completion Signal

- When playback finishes (naturally or via "Stop sending"), the view model sets `appState = .reveal` on the **main thread**.
- A `@Published var morseDone: Bool` property on the view model is set to `true` on completion and reset to `false` at the start of each new playback session.
- UI tests use this published property (via accessibility identifiers) to detect completion.

### 9.6 Playback Trigger

Morse plays the extracted sentence immediately after a successful fetch. No additional user interaction is required to start playback after tapping "Find an article".

### 9.7 Punctuation in Playback

Punctuation present in the sentence must be transmitted as Morse code:

| Character | Morse |
|-----------|-------|
| `.` | `.-.-.-` |
| `,` | `--..--` |
| `?` | `..--..` |
| `'` | `.----.` |
| `!` | `-.-.--` |
| `/` | `-..-.` |
| `(` | `-.--.` |
| `)` | `-.--.-` |
| `&` | `.-...` |
| `:` | `---...` |
| `;` | `-.-.-.` |
| `=` | `-...-` |
| `+` | `.-.-.` |
| `-` | `-....-` |
| `_` | `..--.-` |
| `"` | `.-..-.` |
| `$` | `...-..-` |
| `@` | `.--.-.` |

Any punctuation not in this table is silently skipped.

---

## 10. Visual Design

- Background: `#1a1a1a` (very dark grey) — applied as the app's global background
- Accent / label color: `#ff4d00` (orange-red)
- Text box and button background: `#e8e8e8` (very light grey)
- Text box and button text: `.black`
- Define colors as named `Color` assets in `Assets.xcassets` for easy theming:
  - `AppBackground` → `#1a1a1a`
  - `AppAccent` → `#ff4d00`
  - `SurfaceBackground` → `#e8e8e8`
- The layout must be usable on all current iPhone screen sizes (iPhone SE through iPhone Pro Max) in portrait orientation.
- **iPhone is locked to portrait only** (`UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait`).
- **iPad supports all orientations.** In portrait, the layout matches iPhone. In landscape, a two-column layout is used: the left column (62% width) holds the Telegram frame and text box; the right column (38% width) holds the controls and button. The header and footer span the full width above and below the columns respectively.
- Support Dynamic Type for accessibility (use relative font sizes where practical).

---

## 11. XCTest Suite (`MorseTraineriOSTests.swift`)

All major logic must be covered by unit tests. UI tests use `XCUIApplication`.

### 11.1 Launch Tests

- App launches without crashing.
- Title label contains "Morse Trainer".
- Footer label contains the attribution string.
- Text box is visible and shows placeholder text.

### 11.2 Speed Slider Tests

- Slider is present with default value `30` (WPM).
- Speed readout label displays `30` on launch.
- Changing the slider updates the readout in real time.

### 11.3 Button Tests

- "Find an article" button is visible and labeled correctly on launch.
- Tapping "Find an article" transitions the button to "Loading…" then "Stop sending".
- After playback completes, button label changes to "Reveal".
- Tapping "Reveal" populates Line 1 with text beginning `Title:`.
- Tapping "Reveal" populates Line 2 with text beginning `Sentence:`.
- Tapping "Reveal" populates Line 3 with text beginning `Source:` and containing a valid URL.
- Tapping "Reveal" returns the button label to "Find an article".

### 11.4 Morse Playback Tests

- After tapping "Find an article", `morseDone` eventually becomes `true` (allow up to 30 s).
- Adjusting the slider mid-playback does not throw an error.
- `morseDone` is reset to `false` at the start of each new playback session.

### 11.5 Speed Change During Playback

- Start playback, programmatically change the slider value mid-transmission; verify no crash and `morseDone` still becomes `true`.

### 11.6 Stop Sending / Reveal Flow

- While sending, button label is "Stop sending".
- Tapping "Stop sending" halts playback immediately, sets text box to "Stopped …", and button to "Reveal".
- Tapping "Stop sending" sets `morseDone` to `true` immediately.
- When playback completes naturally, text box shows "Send complete…" and button shows "Reveal".
- Tapping "Reveal" after natural completion populates `Title:`, `Sentence:`, and `Source:` lines.
- Tapping "Reveal" after "Stop sending" populates the same three lines.
- After "Reveal", button returns to "Find an article".
- Button never shows "Stop sending" when no playback is in progress.

### 11.7 Learn Mode Tests

- Mode picker is present.
- Default selection is **Test**.
- In Test mode, text box shows "Sending …" during playback (not decoded characters).
- Switching to Learn mode and tapping "Find an article" causes plaintext characters to appear in the text box during playback.
- In Learn mode, `morseDone` still becomes `true` after playback completes.
- In Learn mode, the decoded sentence remains in the text box after playback completes (not replaced with "Send complete…").
- In Learn mode, tapping "Stop sending" halts playback and advances to Reveal state.
- In Learn mode, tapping "Reveal" populates the full `Title:`, `Sentence:`, and `Source:` lines.

---

## 12. Key View Model Properties and Accessibility Identifiers

| Property / Identifier | Type | Purpose |
|-----------------------|------|---------|
| `appState` | `enum AppState` | `.idle`, `.loading`, `.sending`, `.reveal` |
| `morseDone` | `@Published Bool` | Signals playback completion to tests |
| `mode` | `enum Mode` | `.learn`, `.test` |
| `wpm` | `@Published Int` | Current speed in WPM (converted to CPM ×5 for engine) |
| `displayText` | `@Published String` | Text box content |
| `"textbox"` | Accessibility ID | Text display area |
| `"modeSwitch"` | Accessibility ID | Learn/Test picker |
| `"speedSlider"` | Accessibility ID | WPM slider |
| `"speedLabel"` | Accessibility ID | Live WPM readout |
| `"findBtn"` | Accessibility ID | Primary action button |

---

*End of Specifications*
