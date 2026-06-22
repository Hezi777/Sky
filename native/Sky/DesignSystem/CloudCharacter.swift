import SwiftUI

// Cloud mood character. Ports lib/cloud-state.ts — first matching rule wins.

enum CloudState: String, CaseIterable {
    case hero, sleeping, stretching, happy, confident, droopy, calm

    var assetName: String { "cloud-\(rawValue)" }
    var skyAssetName: String { "sky-\(rawValue)" }
}

// Mood greeting (ports lib/cloud-greeting.ts).
struct CloudGreeting {
    let primary: String
    let secondary: String
}

extension Cloud {
    static func greeting(for state: CloudState, name: String) -> CloudGreeting {
        let table: [CloudState: (String, String)] = [
            .sleeping:   ("Good night, \(name)",     "Time to rest. Sky will be here in the morning."),
            .stretching: ("Good morning, \(name)",   "Fresh start. Let's see what today brings."),
            .happy:      ("You're on fire, \(name)", "Great momentum today. Keep it going."),
            .confident:  ("Looking good, \(name)",   "Portfolio's green today."),
            .droopy:     ("Hey \(name)",             "Quiet day. That's okay too."),
            .calm:       ("Winding down, \(name)",   "Good day. Time to wrap up."),
            .hero:       ("Hey \(name)",             "Welcome to Sky."),
        ]
        let (p, s) = table[state] ?? ("Hey \(name)", "Welcome to Sky.")
        return CloudGreeting(primary: p, secondary: s)
    }
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

/// The cloud avatar image. Roles keep every mood asset consistently sized for
/// its placement and platform.
struct CloudAvatar: View {
    enum Role {
        case hero
        case status
        case placeholder

        var size: CGFloat {
            switch self {
            case .hero: Tokens.Size.heroCharacter
            case .status: Tokens.Size.statusCharacter
            case .placeholder: Tokens.Size.placeholderCharacter
            }
        }
    }

    let state: CloudState
    let role: Role

    var body: some View {
        Image(state.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: role.size, height: role.size)
            .accessibilityHidden(true)
    }
}
