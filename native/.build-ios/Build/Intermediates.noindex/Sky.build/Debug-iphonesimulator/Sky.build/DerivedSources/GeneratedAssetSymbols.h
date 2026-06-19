#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.hen.sky.native";

/// The "BgBase" asset catalog color resource.
static NSString * const ACColorNameBgBase AC_SWIFT_PRIVATE = @"BgBase";

/// The "CardBg" asset catalog color resource.
static NSString * const ACColorNameCardBg AC_SWIFT_PRIVATE = @"CardBg";

/// The "Chart1" asset catalog color resource.
static NSString * const ACColorNameChart1 AC_SWIFT_PRIVATE = @"Chart1";

/// The "Chart2" asset catalog color resource.
static NSString * const ACColorNameChart2 AC_SWIFT_PRIVATE = @"Chart2";

/// The "Chart3" asset catalog color resource.
static NSString * const ACColorNameChart3 AC_SWIFT_PRIVATE = @"Chart3";

/// The "Chart4" asset catalog color resource.
static NSString * const ACColorNameChart4 AC_SWIFT_PRIVATE = @"Chart4";

/// The "Chart5" asset catalog color resource.
static NSString * const ACColorNameChart5 AC_SWIFT_PRIVATE = @"Chart5";

/// The "Github1" asset catalog color resource.
static NSString * const ACColorNameGithub1 AC_SWIFT_PRIVATE = @"Github1";

/// The "Github2" asset catalog color resource.
static NSString * const ACColorNameGithub2 AC_SWIFT_PRIVATE = @"Github2";

/// The "Github3" asset catalog color resource.
static NSString * const ACColorNameGithub3 AC_SWIFT_PRIVATE = @"Github3";

/// The "Github4" asset catalog color resource.
static NSString * const ACColorNameGithub4 AC_SWIFT_PRIVATE = @"Github4";

/// The "GithubEmpty" asset catalog color resource.
static NSString * const ACColorNameGithubEmpty AC_SWIFT_PRIVATE = @"GithubEmpty";

/// The "GlowPrimary" asset catalog color resource.
static NSString * const ACColorNameGlowPrimary AC_SWIFT_PRIVATE = @"GlowPrimary";

/// The "GlowSecondary" asset catalog color resource.
static NSString * const ACColorNameGlowSecondary AC_SWIFT_PRIVATE = @"GlowSecondary";

/// The "SkyPrimary" asset catalog color resource.
static NSString * const ACColorNameSkyPrimary AC_SWIFT_PRIVATE = @"SkyPrimary";

/// The "cloud-calm" asset catalog image resource.
static NSString * const ACImageNameCloudCalm AC_SWIFT_PRIVATE = @"cloud-calm";

/// The "cloud-confident" asset catalog image resource.
static NSString * const ACImageNameCloudConfident AC_SWIFT_PRIVATE = @"cloud-confident";

/// The "cloud-droopy" asset catalog image resource.
static NSString * const ACImageNameCloudDroopy AC_SWIFT_PRIVATE = @"cloud-droopy";

/// The "cloud-happy" asset catalog image resource.
static NSString * const ACImageNameCloudHappy AC_SWIFT_PRIVATE = @"cloud-happy";

/// The "cloud-hero" asset catalog image resource.
static NSString * const ACImageNameCloudHero AC_SWIFT_PRIVATE = @"cloud-hero";

/// The "cloud-sleeping" asset catalog image resource.
static NSString * const ACImageNameCloudSleeping AC_SWIFT_PRIVATE = @"cloud-sleeping";

/// The "cloud-stretching" asset catalog image resource.
static NSString * const ACImageNameCloudStretching AC_SWIFT_PRIVATE = @"cloud-stretching";

#undef AC_SWIFT_PRIVATE
