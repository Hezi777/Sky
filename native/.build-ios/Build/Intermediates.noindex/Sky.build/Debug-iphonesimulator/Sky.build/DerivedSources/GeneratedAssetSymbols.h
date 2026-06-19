#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

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
