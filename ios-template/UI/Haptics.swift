import UIKit
import SwiftUI

/// Minimal haptics for M0; `HapticsService` protocol + Core Haptics land in M1 (BF-110).
@MainActor
enum Haptics {
    static var enabled = true
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func impactLater(after delay: TimeInterval, style: UIImpactFeedbackGenerator.FeedbackStyle) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            impact(style)
        }
    }
    static func selection() { if enabled { UISelectionFeedbackGenerator().selectionChanged() } }
    static func warning() { if enabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) } }
}
