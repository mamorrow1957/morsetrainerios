import SwiftUI
import UIKit

@main
struct MorseTrainerIOSApp: App {

    init() {
        // Make the non-selected segment clearly readable on a dark background
        UISegmentedControl.appearance().backgroundColor = UIColor(white: 0.25, alpha: 1)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(white: 0.55, alpha: 1)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.black], for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
