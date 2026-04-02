import SwiftUI

struct ContentView: View {

    @StateObject private var vm = MorseViewModel()

    // Colors
    private let appBackground  = Color(hex: "#1a1a1a")
    private let accent         = Color(hex: "#ff4d00")
    private let surface        = Color(hex: "#e8e8e8")

    var body: some View {
        ZStack {
            appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                header

                // MARK: Main content
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MARK: Footer
                footer
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        Text("Morse Trainer")
            .font(.largeTitle.bold())
            .foregroundColor(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }

    private var footer: some View {
        Text("vibe coded in Feb–Mar 2026 by Michael Morrow")
            .font(.caption)
            .foregroundColor(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Text box
            textBox
                .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            // Mode picker + speed slider side by side area
            controls
                .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            // Action button
            actionButton
                .padding(.horizontal, 20)

            Spacer()
            Spacer().frame(height: 30)
        }
    }

    // MARK: Text box

    @ViewBuilder
    private var textBox: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(surface)

            if vm.displayText.hasPrefix("Title:"), let title = vm.revealTitle {
                // Structured reveal view
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title: ").bold() + Text(title)
                    if let sentence = vm.revealSentence {
                        Text("Sentence: ").bold() + Text(sentence)
                    }
                    if let url = vm.revealURL {
                        HStack(spacing: 0) {
                            Text("Source: ").bold().foregroundColor(.black)
                            Link(url.absoluteString, destination: url)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .font(.body)
                .foregroundColor(.black)
                .padding(12)

            } else if vm.displayText.isEmpty {
                Text("Press the button …")
                    .foregroundColor(Color(white: 0.5))
                    .font(.body)
                    .padding(12)
            } else {
                Text(vm.displayText)
                    .foregroundColor(vm.errorText != nil ? .red : .black)
                    .font(.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .accessibilityIdentifier("textbox")
    }

    // MARK: Controls

    private var controls: some View {
        HStack(alignment: .top, spacing: 16) {
            // Mode picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Mode")
                    .font(.caption)
                    .foregroundColor(accent)
                Picker("Mode", selection: $vm.mode) {
                    Text("Learn").tag(Mode.learn)
                    Text("Test").tag(Mode.test)
                }
                .pickerStyle(.segmented)
                .disabled(vm.appState == .sending || vm.appState == .loading)
                .accessibilityIdentifier("modeSwitch")
            }
            .frame(maxWidth: .infinity)

            // Speed slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed: \(vm.cpm) CPM")
                    .font(.caption)
                    .foregroundColor(accent)
                    .accessibilityIdentifier("speedLabel")
                Slider(value: Binding(
                    get: { Double(vm.cpm) },
                    set: { vm.cpm = Int($0) }
                ), in: 50...150, step: 1)
                .accessibilityIdentifier("speedSlider")
                .tint(accent)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Button

    private var actionButton: some View {
        Button(action: { vm.buttonTapped() }) {
            Text(buttonLabel)
                .font(.title3.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(surface)
                .cornerRadius(8)
        }
        .disabled(vm.appState == .loading)
        .accessibilityIdentifier("findBtn")
    }

    private var buttonLabel: String {
        switch vm.appState {
        case .idle:    return "Find an article"
        case .loading: return "Loading…"
        case .sending: return "Stop sending"
        case .reveal:  return "Reveal"
        }
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
}
