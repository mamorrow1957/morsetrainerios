import Foundation
import AVFoundation

// MARK: - Morse code table

private let morseTable: [Character: String] = [
    "A": ".-",    "B": "-...",  "C": "-.-.",  "D": "-..",
    "E": ".",     "F": "..-.",  "G": "--.",   "H": "....",
    "I": "..",    "J": ".---",  "K": "-.-",   "L": ".-..",
    "M": "--",    "N": "-.",    "O": "---",   "P": ".--.",
    "Q": "--.-",  "R": ".-.",   "S": "...",   "T": "-",
    "U": "..-",   "V": "...-",  "W": ".--",   "X": "-..-",
    "Y": "-.--",  "Z": "--..",
    "0": "-----", "1": ".----", "2": "..---", "3": "...--",
    "4": "....-", "5": ".....", "6": "-....", "7": "--...",
    "8": "---..", "9": "----.",
    ".": ".-.-.-", ",": "--..--", "?": "..--..", "'": ".----.",
    "!": "-.-.--", "/": "-..-.",  "(": "-.--.",  ")": "-.--.-",
    "&": ".-...",  ":": "---...", ";": "-.-.-.",  "=": "-...-",
    "+": ".-.-.",  "-": "-....-", "_": "..--.-.","\"": ".-..-.",
    "$": "...-..-","@": ".--.-."
]

// MARK: - MorseEngine

final class MorseEngine {

    // Called on the main thread when a character index is about to start transmitting.
    // Used by Learn mode to reveal characters in real time.
    var onCharacterStart: ((Int) -> Void)?

    // Called on the main thread when playback finishes or is stopped.
    var onComplete: (() -> Void)?

    private let frequency: Double = 650.0
    private let sampleRate: Double = 44100.0
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var isStopped = false
    private var playbackTask: Task<Void, Never>?

    // MARK: - Public API

    func play(sentence: String, cpmProvider: @escaping () -> Int) {
        stop()
        isStopped = false
        setupAudioSession()
        setupEngine()

        playbackTask = Task {
            await transmit(sentence: sentence, cpmProvider: cpmProvider)
            if !isStopped {
                await MainActor.run { self.onComplete?() }
            }
        }
    }

    func stop() {
        isStopped = true
        playbackTask?.cancel()
        playbackTask = nil
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
    }

    // MARK: - Audio setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            // Silent fallback — timing loop still runs
        }
    }

    private func setupEngine() {
        let newEngine = AVAudioEngine()
        let node = AVAudioPlayerNode()
        newEngine.attach(node)
        newEngine.connect(node, to: newEngine.mainMixerNode, format: audioFormat)
        do {
            try newEngine.start()
        } catch {
            // Silent fallback
        }
        engine = newEngine
        playerNode = node
        node.play()
    }

    // MARK: - Transmission loop

    private func transmit(sentence: String, cpmProvider: @escaping () -> Int) async {
        let chars = Array(sentence.uppercased())
        var charIndex = 0

        while charIndex < chars.count {
            guard !isStopped && !Task.isCancelled else { return }

            let ch = chars[charIndex]

            if ch == " " {
                let idx = charIndex
                await MainActor.run { self.onCharacterStart?(idx) }
                let unit = unitSeconds(cpm: cpmProvider())
                await silence(duration: unit * 3.5)
            } else if let pattern = morseTable[ch] {
                let idx = charIndex
                await MainActor.run { self.onCharacterStart?(idx) }

                let symbols = Array(pattern)
                for (symIdx, sym) in symbols.enumerated() {
                    guard !isStopped && !Task.isCancelled else { return }
                    let unit = unitSeconds(cpm: cpmProvider())

                    if sym == "." {
                        await tone(duration: unit)
                    } else {
                        await tone(duration: unit * 3)
                    }

                    guard !isStopped && !Task.isCancelled else { return }

                    // Intra-character gap (not after last symbol)
                    if symIdx < symbols.count - 1 {
                        let u = unitSeconds(cpm: cpmProvider())
                        await silence(duration: u)
                    }
                }

                // Inter-character gap (if next character is not a space)
                let nextIdx = charIndex + 1
                if nextIdx < chars.count && chars[nextIdx] != " " {
                    let unit = unitSeconds(cpm: cpmProvider())
                    await silence(duration: unit * 3)
                }
            }
            // Unknown characters are silently skipped

            charIndex += 1
        }
    }

    // MARK: - Timing helpers

    private func unitSeconds(cpm: Int) -> Double {
        60.0 / (Double(max(cpm, 1)) * 8.0)
    }

    private func tone(duration: Double) async {
        guard let node = playerNode, let eng = engine, eng.isRunning else {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            return
        }

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            return
        }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // Raised-cosine envelope to avoid clicks
            let envelope: Double
            let attack = min(0.005, duration * 0.1)
            let decay  = min(0.005, duration * 0.1)
            if t < attack {
                envelope = t / attack
            } else if t > duration - decay {
                envelope = (duration - t) / decay
            } else {
                envelope = 1.0
            }
            data[i] = Float(sin(2.0 * .pi * frequency * t) * envelope * 0.8)
        }

        await node.scheduleBuffer(buffer)
    }

    private func silence(duration: Double) async {
        guard duration > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}
