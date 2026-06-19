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

