import SwiftUI
import UIKit

@main
struct MorseTrainerIOSApp: App {

    init() {
        // Make the non-selected segment clearly readable on a dark background
        UISegmentedControl.appearance().backgroundColor = UIColor(white: 0.25, alpha: 1)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 1.0, green: 0.302, blue: 0.0, alpha: 1) // #ff4d00
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.black], for: .selected)

        // Match slider unselected track to segmented control background
        UISlider.appearance().maximumTrackTintColor = UIColor(white: 0.25, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
