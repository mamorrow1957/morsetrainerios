import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var vm = MorseViewModel()

    // Colors
    private let appBackground  = Color(hex: "#1a1a1a")
    private let accent         = Color(hex: "#ff4d00")
    private let surface        = Color(hex: "#e8e8e8")
    private let headerColor    = Color(hex: "#e0e0e0")

    // Typewriter header animation
    private let fullTitle = "Morse Trainer"
    @State private var visibleCharCount = 0
    @State private var typewriterPlayer = TypewriterPlayer()

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

    private var headerString: AttributedString {
        var str = AttributedString(fullTitle)
        var i = 0
        var idx = str.startIndex
        while idx < str.endIndex {
            let next = str.index(afterCharacter: idx)
            str[idx..<next].foregroundColor = i < visibleCharCount ? headerColor : .clear
            i += 1
            idx = next
        }
        return str
    }

    private var header: some View {
        Text(headerString)
            .font(.custom("1942report", size: 300))
            .minimumScaleFactor(0.01)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .onAppear {
                visibleCharCount = 0
                for i in 1...fullTitle.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                        visibleCharCount = i
                        typewriterPlayer.click()
                    }
                }
            }
    }

    private var footer: some View {
        Text("vibe coded in Feb–Apr 2026 by Michael Morrow")
            .font(.caption)
            .foregroundColor(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    private var mainContent: some View {
        GeometryReader { geo in
            let h = geo.size.height
            VStack(spacing: 0) {
                Spacer()

                // Telegram images + text box as a single framed unit
                VStack(spacing: 0) {
                    Image("TelegramTop")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)

                    textBox(height: h * 0.36)

                    Image("TelegramBottom")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: h * 0.03)

                // Mode picker + speed slider
                controls
                    .padding(.horizontal, 20)

                Spacer().frame(height: h * 0.03)

                // Action button
                actionButton
                    .padding(.horizontal, 20)

                // Extra bottom space to sit slightly above center
                Spacer()
                Spacer().frame(height: h * 0.19)
            }
        }
    }

    // MARK: Text box

    @ViewBuilder
    private func textBox(height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.white)

            ScrollView {
                if vm.displayText.hasPrefix("Title:"), let title = vm.revealTitle {
                    // Structured reveal view
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title: ").bold() + Text(title)
                        if let sentence = vm.revealSentence {
                            Text("Sentence: ").bold() + Text(sentence)
                        }
                        if let url = vm.revealURL {
                            (Text("Source: ").bold().foregroundColor(.black)
                            + Text(url.absoluteString).foregroundColor(.blue))
                                .onTapGesture { UIApplication.shared.open(url) }
                        }
                    }
                    .font(.custom("AmericanTypewriter", size: 17))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                } else if vm.displayText.isEmpty {
                    Text("Press the button …")
                        .foregroundColor(Color(white: 0.5))
                        .font(.custom("AmericanTypewriter", size: 17))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(vm.displayText)
                        .foregroundColor(vm.errorText != nil ? .red : .black)
                        .font(.custom("AmericanTypewriter", size: 17))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .accessibilityIdentifier("textbox")
        .clipped()
    }

    // MARK: Controls

    private var controls: some View {
        HStack(alignment: .top, spacing: 16) {
            // Mode picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Mode")
                    .font(.subheadline)
                    .foregroundColor(accent)
                Picker("Mode", selection: $vm.mode) {
                    Text("Learn").tag(Mode.learn)
                    Text("Test").tag(Mode.test)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("modeSwitch")
            }
            .frame(width: 120)

            // Speed slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed: \(vm.wpm) WPM")
                    .font(.subheadline)
                    .foregroundColor(accent)
                    .accessibilityIdentifier("speedLabel")
                Slider(value: Binding(
                    get: { Double(vm.wpm) },
                    set: { vm.wpm = Int($0) }
                ), in: 10...50, step: 1)
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
                .font(.custom("AmericanTypewriter-Bold", size: 20))
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

// MARK: - Typewriter click sound

private class TypewriterPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    func click() {
        let sampleRate = 44100.0
        let duration   = 0.018  // 18 ms — shorter, snappier click
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Two-stage envelope: sharp attack spike then slower mechanical decay
            let envelope = (t < 0.002 ? t / 0.002 : exp(-(t - 0.002) * 90.0))

            // Fundamental + 2nd harmonic for body
            let tone = sin(2.0 * .pi * 800.0 * t) * 0.4
                     + sin(2.0 * .pi * 1600.0 * t) * 0.2

            // White noise for the mechanical clack character
            let noise = Float.random(in: -1.0...1.0) * 0.55

            data[i] = Float((tone + Double(noise)) * envelope * 0.35)
        }

        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying { player.play() }
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
