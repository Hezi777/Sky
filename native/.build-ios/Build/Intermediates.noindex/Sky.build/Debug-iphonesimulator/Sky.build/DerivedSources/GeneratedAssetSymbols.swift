import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "BgBase" asset catalog color resource.
    static let bgBase = DeveloperToolsSupport.ColorResource(name: "BgBase", bundle: resourceBundle)

    /// The "CardBg" asset catalog color resource.
    static let cardBg = DeveloperToolsSupport.ColorResource(name: "CardBg", bundle: resourceBundle)

    /// The "Chart1" asset catalog color resource.
    static let chart1 = DeveloperToolsSupport.ColorResource(name: "Chart1", bundle: resourceBundle)

    /// The "Chart2" asset catalog color resource.
    static let chart2 = DeveloperToolsSupport.ColorResource(name: "Chart2", bundle: resourceBundle)

    /// The "Chart3" asset catalog color resource.
    static let chart3 = DeveloperToolsSupport.ColorResource(name: "Chart3", bundle: resourceBundle)

    /// The "Chart4" asset catalog color resource.
    static let chart4 = DeveloperToolsSupport.ColorResource(name: "Chart4", bundle: resourceBundle)

    /// The "Chart5" asset catalog color resource.
    static let chart5 = DeveloperToolsSupport.ColorResource(name: "Chart5", bundle: resourceBundle)

    /// The "Github1" asset catalog color resource.
    static let github1 = DeveloperToolsSupport.ColorResource(name: "Github1", bundle: resourceBundle)

    /// The "Github2" asset catalog color resource.
    static let github2 = DeveloperToolsSupport.ColorResource(name: "Github2", bundle: resourceBundle)

    /// The "Github3" asset catalog color resource.
    static let github3 = DeveloperToolsSupport.ColorResource(name: "Github3", bundle: resourceBundle)

    /// The "Github4" asset catalog color resource.
    static let github4 = DeveloperToolsSupport.ColorResource(name: "Github4", bundle: resourceBundle)

    /// The "GithubEmpty" asset catalog color resource.
    static let githubEmpty = DeveloperToolsSupport.ColorResource(name: "GithubEmpty", bundle: resourceBundle)

    /// The "GlowPrimary" asset catalog color resource.
    static let glowPrimary = DeveloperToolsSupport.ColorResource(name: "GlowPrimary", bundle: resourceBundle)

    /// The "GlowSecondary" asset catalog color resource.
    static let glowSecondary = DeveloperToolsSupport.ColorResource(name: "GlowSecondary", bundle: resourceBundle)

    /// The "SkyPrimary" asset catalog color resource.
    static let skyPrimary = DeveloperToolsSupport.ColorResource(name: "SkyPrimary", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "cloud-calm" asset catalog image resource.
    static let cloudCalm = DeveloperToolsSupport.ImageResource(name: "cloud-calm", bundle: resourceBundle)

    /// The "cloud-confident" asset catalog image resource.
    static let cloudConfident = DeveloperToolsSupport.ImageResource(name: "cloud-confident", bundle: resourceBundle)

    /// The "cloud-droopy" asset catalog image resource.
    static let cloudDroopy = DeveloperToolsSupport.ImageResource(name: "cloud-droopy", bundle: resourceBundle)

    /// The "cloud-happy" asset catalog image resource.
    static let cloudHappy = DeveloperToolsSupport.ImageResource(name: "cloud-happy", bundle: resourceBundle)

    /// The "cloud-hero" asset catalog image resource.
    static let cloudHero = DeveloperToolsSupport.ImageResource(name: "cloud-hero", bundle: resourceBundle)

    /// The "cloud-sleeping" asset catalog image resource.
    static let cloudSleeping = DeveloperToolsSupport.ImageResource(name: "cloud-sleeping", bundle: resourceBundle)

    /// The "cloud-stretching" asset catalog image resource.
    static let cloudStretching = DeveloperToolsSupport.ImageResource(name: "cloud-stretching", bundle: resourceBundle)

}

