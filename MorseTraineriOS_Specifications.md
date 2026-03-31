# Morse Trainer Web — Project Specifications

---

## 1. Project Overview

**Morse Trainer Web** is a single-page browser application that fetches random Wikipedia articles and plays the first sentence as Morse code via the Web Audio API. The article content is deliberately withheld during transmission and only revealed afterwards, so the user can practise decoding the code before seeing the answer. The user can adjust playback speed in real time, even while code is being sent.

---

## 2. File Structure

```
morse-trainer-web/
├── index.html
├── style.css
├── script.js
└── tests/
    └── app.spec.js          # Playwright test suite
```

---

## 3. Page Layout

### 3.1 Overall Structure

The page is divided into three full-width sections that together occupy the entire viewport:

| Section | Element | Background Color |
|---------|---------|-----------------|
| Header | `<header>` | Very dark grey |
| Main Content | `<main>` | Very dark grey |
| Footer | `<footer>` | Very dark grey |

The page must fill the entire screen with no scrollbars (unless content overflows on very small screens).

### 3.2 Header

- Contains the site title: **"Morse Trainer Web"**
- Text color: `#ff4d00`
- Clean, centered title typography consistent with the overall modern design

### 3.3 Footer

- Contains the attribution string: **"vibe coded in Feb-Mar 2026 by Michael Morrow"**
- Text color: `#ff4d00`
- Attribution is centered

### 3.4 Main Content Area

The main content section holds the text box, the Learn/Test mode switch, the speed control, and the button. It uses flexbox or equivalent to center its children both horizontally and vertically.

---

## 4. Text Box (`#textbox`)

| Property | Value |
|----------|-------|
| Background | Very light grey |
| Text color | Black |
| Width | 67% of the main content section width |
| Height | 33% of the main content section height |
| Horizontal position | Centered |
| Vertical center point | 33% of the distance from the top of the main content area |
| Font size | Large enough to comfortably display 5 rows of text |
| Placeholder text | **"Press the button …"** — same font size as the content text |

The text box is read-only from the user's perspective (content is populated programmatically). It must be capable of rendering a clickable hyperlink on its third line (see §8 — Article Display).

### 4.1 Text Box States

| State | Text Box Content |
|-------|-----------------|
| Idle (initial load or after Reveal) | Placeholder text: **"Press the button …"** |
| Sending | **"Sending …"** — replaces placeholder while Morse is playing |
| Finished | **"Send complete…"** — shown when Morse playback completes naturally |
| Stopped | **"Stopped …"** — shown when the user clicks "Stop sending" to halt playback early |
| Reveal | The three article lines (Title, Sentence, Source) as described in §8 |

---

## 5. Learn/Test Mode Switch (`#mode-switch`)

A two-position toggle switch is placed to the **left of the controls area**, with its **top edge vertically aligned with the speed label** ("Speed: X CPM") above the slider.

| Property | Value |
|----------|-------|
| Position | Left-aligned with the left edge of `#textbox`; top edge aligned with the speed label above the slider |
| Choices | **"Learn"** (left) and **"Test"** (right) |
| Default | **"Test"** |
| Label color | `#ff4d00` |
| Label font size | Same as the speed label (`#morse-speed-value` line) |

### 5.1 Test Mode (default)

When the switch is set to **Test**, the application behaves exactly as described in the rest of this specification — article content is hidden during Morse playback and revealed only when the user clicks "Reveal" (or when "Stop sending" is clicked).

### 5.2 Learn Mode

When the switch is set to **Learn**, the app reveals each character to the user **as its Morse code is transmitted** at the currently selected speed. Specifically:

- The text box **starts empty** when playback begins (no `"Sending …"` message is shown in Learn mode).
- The text box shows the accumulated plaintext characters decoded so far, updated in real time.
- Characters appear one at a time: each character is appended to the text box **as its first Morse symbol (dit or dah) begins transmitting**.
- Word spaces are appended to the text box as the inter-word gap begins (i.e., when the first tone of the preceding character's word finishes and the gap starts).
- **Stop and Reveal** behave identically to Test mode:
  - Clicking "Stop sending" halts playback immediately, sets `data-morse-done="true"`, and advances the button to "Reveal".
  - Clicking "Reveal" replaces the text box content with the full three-line article display (Title, Sentence, Source) as defined in §8, and returns the button to "Find an article".
- Switching between Learn and Test **while playback is in progress** is not required to be supported; the switch may be disabled during active playback.

---

## 6. Controls Area (`.controls`)

The controls area sits below the text box and groups the speed slider and the "Find an article" button. It is centered horizontally and offset from the bottom of the text box by **3% of the window height**.

### 6.1 Speed Slider (`#morse-speed`)

| Property           | Value                                                           |
| ------------------ | --------------------------------------------------------------- |
| Type               | Range input                                                     |
| Minimum            | 50 CPM                                                          |
| Maximum            | 150 CPM                                                         |
| Default value      | 100 CPM                                                         |
| Text / label color | `#ff4d00`                                                       |
| Associated display | `#morse-speed-value` — shows the current CPM value in real time |

The slider label and value display must remain visible and legible against the dark background. The user **may adjust the slider at any time, including during active Morse playback**; the running transmission must adopt the new speed immediately (see §9.3).

### 6.2 Button (`#find-btn`)

| Property | Value |
|----------|-------|
| Width | 10% of the window width |
| Background | Same color as the text box (very light grey) |
| Text color | Black |
| Font size | Large enough to fill the button visually |
| Horizontal position | Centered |

The button cycles through four states depending on the application state:

| State | Label | Action on click |
|-------|-------|-----------------|
| **Idle** | **"Find an article"** | Fetch article, begin Morse playback, enter Sending state |
| **Sending** | **"Stop sending"** | Immediately halt playback and enter Reveal state |
| **Reveal** | **"Reveal"** | Populate text box with article content (§8), enter Idle state |
| *(loading)* | **"Loading…"** | Disabled — fetch in progress |

State transition rules:
1. On page load the button is in **Idle** state.
2. Clicking **"Find an article"** fetches the article, changes the text box to `"Sending …"`, and — once the fetch succeeds — begins Morse playback and switches the button to **Sending**.
3. When Morse playback completes naturally, the text box changes to `"Send complete…"` and the button automatically advances to **Reveal**.
4. Clicking **"Stop sending"** immediately halts Morse playback, changes the text box to `"Stopped …"`, and advances directly to **Reveal** state (skipping any remaining transmission).
5. Clicking **"Reveal"** populates the text box with the three article lines (§8) and returns the button to **Idle**. The article content remains visible until the next "Find an article" click.
6. The button must **never** display **"Stop sending"** when no Morse playback is in progress.

---

## 7. Wikipedia Article Fetching

When the "Find an article" button is clicked:

1. A **random English Wikipedia article** is fetched using the Wikipedia API random-page endpoint.
2. The article title, body content, and URL are retrieved and stored internally.
3. The text box changes to `"Sending …"` and Morse playback of the extracted sentence begins (see §9).
4. The article content (title, sentence, source) is **not** shown until the user clicks **"Reveal"** (see §6.2 and §8).

Suitable API endpoint:

```
https://en.wikipedia.org/api/rest_v1/page/random/summary
```

or the equivalent `action=query&list=random` MediaWiki API call that also returns parseable content.

The fetch must have a **10-second timeout**. If the request does not complete within 10 seconds, it is aborted, an error message is shown in the text box, and the button is restored to `"Find an article"` so the user can retry.

If the fetch fails for any reason (timeout, HTTP error, network failure), the application must:
- Display a red error message in the text box: `"Error fetching article: <reason>"`
- Set `data-morse-done="true"` on `#textbox`
- Re-enable the button and restore its label to `"Find an article"`
- Return `_appState` to `'idle'`

---

## 8. Article Display

The article content is revealed only when the user clicks **"Reveal"** (or when **"Stop sending"** is pressed, which triggers Reveal immediately). At that point the text box is populated with exactly three lines:

| Line | Format |
|------|--------|
| Line 1 | `Title: <article title>` |
| Line 2 | `Sentence: <first complete sentence from the article content>` |
| Line 3 | `Source: <article URL>` — rendered as a clickable link that opens in a new tab |

### 8.1 Sentence Extraction Rules

- The target sentence is the **first complete sentence** found in the article's main content section (not the intro stub if it is only a disambiguation or redirect page).
- A sentence ends with a period (`.`), exclamation mark (`!`), or question mark (`?`) followed by a space or end-of-string.
- Sentences must be **longer than 5 words**.
- **Sentences do not end with an abbreviation.** The following abbreviations must not be treated as sentence terminators: titles (`Dr.`, `Mr.`, `Mrs.`, `Ms.`, `Prof.`), common terms (`vs.`, `etc.`, `Jr.`, `Sr.`, `Fig.`, `No.`, `St.`, `Ave.`, `Blvd.`, `Dept.`, `Est.`, `Approx.`), corporate suffixes (`Inc.`, `Ltd.`, `Corp.`), honorifics (`Gov.`, `Gen.`, `Col.`, `Sgt.`, `Cpl.`, `Pvt.`, `Rep.`, `Sen.`, `Rev.`), months (`Jan.`–`Dec.`), days (`Mon.`–`Sun.`), and academic/Latin abbreviations (`Vol.`, `pp.`, `ed.`, `al.`, `ie.`, `eg.`, `op.`, `ca.`, `cf.`, `et.`). Single capital-letter initials (e.g. `J.`) are also excluded.
- Strip any residual wiki markup, citation brackets (e.g., `[1]`), or HTML tags from the extracted text before display.
- **Fallback:** If no sentence longer than 5 words is found, the first 250 characters of the cleaned text are used instead.

---

## 9. Morse Code Playback

### 9.1 Timing Basis

Morse code timing is derived from the **characters-per-minute (CPM)** value currently selected on the speed slider.

The standard unit length (one dot duration) is calculated as:

```
unitMs = 60000 / (CPM * 8)
```

*(This formula treats the average character as approximately 6 units, consistent with the PARIS standard.)*

### 9.2 Element Durations

| Element                                | Duration |
| -------------------------------------- | -------- |
| Dot                                    | 1 unit   |
| Dash                                   | 3 units  |
| Intra-character gap (between dot/dash) | 1 unit   |
| Inter-character gap (between letters)  | 3 units  |
| Inter-word gap                         | 7 units  |

> **Note from original spec:** "Make the length of spaces between words half that of characters." This is interpreted as: inter-word gaps are shortened to half of the standard 7-unit word space, yielding a faster, more compressed playback cadence.

### 9.3 Real-Time Speed Adjustment

- The slider value is sampled **per symbol** (each dot, dash, or gap) rather than once at the start of playback.
- Moving the slider during transmission takes effect on the next scheduled symbol without interrupting the current one.
- No audio glitches or gaps should result from a mid-playback speed change.

### 9.4 Audio Implementation

- Tone generation uses the **Web Audio API** (`AudioContext`, `OscillatorNode`, `GainNode`).
- The tone frequency should be a standard Morse sidetone (e.g., 600–700 Hz).
- No other sounds (beeps, clicks, notifications) are played before or between Morse characters.
- If the Web Audio API is unavailable or blocked, playback falls back to a timed delay (silent mode) so the rest of the UI still functions correctly.

### 9.5 Playback Completion Signal

- When Morse playback of the sentence finishes (naturally or by pressing "Stop sending"), the text box element (`#textbox`) must have `data-morse-done="true"` set on it.
- This attribute is cleared (removed or set to `"false"`) at the start of each new playback session.
- Automated tests use this attribute to detect completion without arbitrary waits.

### 9.6 Playback Trigger

Morse code plays the **extracted sentence** immediately after a successful article fetch. The text box shows `"Sending …"` during playback, `"Send complete…"` when playback ends naturally, and `"Stopped …"` if the user halts playback early. The article content is not shown until the user clicks "Reveal". No user interaction beyond the initial "Find an article" click is required to start playback.

### 9.7 Punctuation in Playback

Punctuation characters present in the sentence **must** be transmitted as Morse code. The following punctuation marks have standard Morse representations and must be included in playback:

| Character | Morse  |
|-----------|--------|
| `.`       | `.-.-.-` |
| `,`       | `--..--` |
| `?`       | `..--..` |
| `'`       | `.----.` |
| `!`       | `-.-.--` |
| `/`       | `-..-.` |
| `(`       | `-.--.` |
| `)`       | `-.--.-` |
| `&`       | `.-...` |
| `:`       | `---...` |
| `;`       | `-.-.-.` |
| `=`       | `-...-` |
| `+`       | `.-.-.` |
| `-`       | `-....-` |
| `_`       | `..--.-` |
| `"`       | `.-..-.` |
| `$`       | `...-..-` |
| `@`       | `.--.-.` |

Any punctuation character not in this table is silently skipped (same behaviour as unknown letters).

---

## 10. CSS & Visual Design

- The design must be **clean and modern**.
- Use CSS custom properties (variables) for repeated color values to simplify future theming.
- Responsive behavior: the layout must remain usable at common desktop resolutions (≥ 1024 px wide). Mobile behavior is a best-effort consideration.
- Suggested dark grey value: `#1a1a1a` or similar (exact shade at developer's discretion, provided it reads as "very dark grey").
- Suggested light grey value: `#e8e8e8` or similar for the text box and button background.

---

## 11. Playwright Test Suite (`tests/app.spec.js`)

All major functionalities must be covered by Playwright tests. The suite should include (at minimum) the tests listed below.

### 11.1 Page Load Tests

- Page loads without errors.
- `<header>` contains the text "Morse Trainer Web".
- `<footer>` contains the attribution string.
- `#textbox` is visible and displays the placeholder text.

### 11.2 Speed Slider Tests

- `#morse-speed` slider is present.
- Default value of `#morse-speed` is `100`.
- `#morse-speed-value` displays `100` on load.
- Changing the slider updates `#morse-speed-value` in real time.

### 11.3 Button Tests

- "Find an article" button is visible and labeled correctly on load.
- Clicking "Find an article" changes the text box to `"Sending …"`.
- Clicking "Find an article" changes the button label to `"Stop sending"` during playback.
- After playback completes, the button label changes to `"Reveal"`.
- Clicking "Reveal" populates Line 1 of `#textbox` with text beginning `Title:`.
- Clicking "Reveal" populates Line 2 with text beginning `Sentence:`.
- Clicking "Reveal" populates Line 3 with text beginning `Source:` and containing a valid URL.
- Clicking "Reveal" returns the button label to `"Find an article"`.
- The URL on Line 3 opens in a new tab when clicked.

### 11.4 Morse Playback Tests

- After clicking "Find an article", `data-morse-done` on `#textbox` is eventually `"true"` (wait with a generous timeout, e.g., 30 s, to accommodate slow CPM values).
- Adjusting the slider mid-playback does not throw a JavaScript error (check browser console).
- `data-morse-done` is cleared/reset to `"false"` at the start of a new "Find an article" click before playback begins.

### 11.5 Speed Change During Playback

- Start playback, then programmatically move the slider to a different value mid-transmission; verify no uncaught exceptions occur and that `data-morse-done` still eventually becomes `"true"`.

### 11.6 Stop Sending / Reveal Flow

- While sending, the button label is `"Stop sending"`.
- Clicking `"Stop sending"` immediately halts playback, sets the text box to `"Stopped …"`, and sets the button label to `"Reveal"`.
- Clicking `"Stop sending"` sets `data-morse-done` to `"true"` immediately.
- When playback completes naturally, the text box changes to `"Send complete…"` and the button label changes to `"Reveal"`.
- Clicking `"Reveal"` after natural playback completion populates the text box with `Title:`, `Sentence:`, and `Source:` lines.
- Clicking `"Reveal"` after pressing `"Stop sending"` populates the text box with the same `Title:`, `Sentence:`, and `Source:` lines.
- After clicking `"Reveal"`, the button returns to `"Find an article"`.
- The button must never display `"Stop sending"` when no Morse playback is in progress.

### 11.7 Learn Mode Tests

- `#mode-switch` is present on the page.
- Default state of `#mode-switch` corresponds to **Test** mode.
- In Test mode, the text box does **not** show decoded characters during playback (it shows `"Sending …"`).
- Switching to Learn mode and clicking "Find an article" causes plaintext characters to appear in `#textbox` during playback (the box should not be empty or show only `"Sending …"` once at least one character has been transmitted).
- In Learn mode, `data-morse-done` still eventually becomes `"true"` after playback completes.
- In Learn mode, clicking `"Stop sending"` still halts playback and advances to Reveal state.
- In Learn mode, clicking `"Reveal"` still populates the text box with the full `Title:`, `Sentence:`, and `Source:` lines.

---

## 12. Summary of Key IDs and Classes

| Identifier | Element | Purpose |
|-----------|---------|---------|
| `#textbox` | `<div>` or `<textarea>` | Article display area; hosts `data-morse-done` |
| `#mode-switch` | `<input type="checkbox">` or toggle | Learn/Test mode selector |
| `#morse-speed` | `<input type="range">` | CPM speed slider |
| `#morse-speed-value` | `<span>` | Live CPM readout |
| `.controls` | `<div>` | Container for slider + button |
| `#find-btn` *(suggested)* | `<button>` | "Find an article" trigger |

---

*End of Specifications*
