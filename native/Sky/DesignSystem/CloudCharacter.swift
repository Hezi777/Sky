import SwiftUI

// Cloud mood character. Ports lib/cloud-state.ts — first matching rule wins.

enum CloudState: String, CaseIterable {
    case hero, sleeping, stretching, happy, confident, droopy, calm

    var assetName: String { "cloud-\(rawValue)" }
}

struct CloudInput {
    var hour: Int
    var githubCommits: Int = 0
    var tasksCompleted: Int = 0
    var daysSinceActivity: Int? = nil
    var portfolioChangePercent: Double? = nil
}

enum Cloud {
    static func state(for input: CloudInput) -> CloudState {
        let h = input.hour
        if h >= 22 || h < 6 { return .sleeping }
        if h >= 6 && h < 9 { return .stretching }
        if input.githubCommits > 3 || input.tasksCompleted > 5 { return .happy }
        if let p = input.portfolioChangePercent, p > 1 { return .confident }
        if let d = input.daysSinceActivity, d >= 2 { return .droopy }
        if h >= 18 && h < 22 { return .calm }
        return .hero
    }

    /// Time-of-day greeting word.
    static func greetingWord(hour: Int) -> String {
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

/// The cloud avatar image, sized for hero or inline use.
struct CloudAvatar: View {
    let state: CloudState
    var size: CGFloat = 96

    var body: some View {
        Image(state.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
