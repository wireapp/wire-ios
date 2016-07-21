// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "WAZUIMagic.h"
#import "Settings.h"

static NSString *const WAZUIMagicDidActivateNotificationName = @"WAZUIMagicDidActivateNotificationName";
static NSString *const versionFileName = @"_version";


@interface WAZUIMagic ()
{
    /// Current active configuration.
    NSDictionary *magics;

    /// Lookup cache, reset with each call to “activate.”
    NSCache *lookupCache;

    /// All known items, loaded by the preloader. Active configuration is a subset of these. Indexed by file names.
    NSMutableDictionary *preloadedMagicItems;

    /// All items (file names) known to the loader.
    NSArray *preloadedMagicItemNames;

    NSOperationQueue *queue;

    /// Device modifier keys.
    NSArray *deviceModifiers;
}

@property (strong, nonatomic, readwrite) NSArray *activeMagicItemNames;

@end



@implementation WAZUIMagic

+ (void)addUIMagicObserver:(id <WAZUIMagicObserver>)observer;
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(UIMagicDidActivate:) name:WAZUIMagicDidActivateNotificationName object:nil];
}

+ (void)removeUIMagicObserver:(id <WAZUIMagicObserver>)observer;
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:WAZUIMagicDidActivateNotificationName object:nil];
}

static WAZUIMagic *singleton = nil;

+ (WAZUIMagic *)sharedMagic
{
    return singleton; // may be nil if hasn’t been properly reset yet with the reset method
}

+ (void)preloadItems:(NSArray *)items
{
    singleton = [[WAZUIMagic alloc] initWithItems:items];
}

+ (void)activateItems:(NSArray *)items
{
    [[self sharedMagic] activateItems:items];
}

- (void)activateItems:(NSArray *)items
{
    DDLogInfo(@"Magic: activateItems: %@", items);
    
    magics = [[NSDictionary alloc] init];
    self.activeMagicItemNames = items;

    for (NSString *item in self.activeMagicItemNames) {
        NSDictionary *candidate = preloadedMagicItems[item];
        if (candidate) {
            magics = [self addEntriesToDictionary:magics fromDictionary:candidate];
        }
    }
    [lookupCache removeAllObjects];

    [[NSNotificationCenter defaultCenter] postNotificationName:WAZUIMagicDidActivateNotificationName object:singleton];
}

- (id)initWithItems:(NSArray *)files
{
    if (self = [super init]) {

        lookupCache = [[NSCache alloc] init];

        preloadedMagicItemNames = files;
        preloadedMagicItems = [[NSMutableDictionary alloc] init];

        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;

        deviceModifiers = @[@"iphone", @"ios", @"default"];

#if TARGET_OS_IPHONE
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            deviceModifiers = @[@"ipad", @"ios", @"default"];
        }
#else
		deviceModifiers = @[@"osx", @"default"];
#endif

        [self reloadFromDisk];

    }
    return self;
}


#pragma mark - Returning values

- (id)objectForKeyedSubscript:(id)key;
{
    return [self objectForKeyPath:key lenient:NO];
}

- (id)objectForKeyPath:(NSString *)keyPath lenient:(BOOL)lenient;
{
    // Fast cache lookup, doesn’t require the complex processing below for often-used values
    id cached = [lookupCache objectForKey:keyPath];
    if (cached) {return cached;}

    id targetKey = keyPath;

    for (NSString *modifier in deviceModifiers) {

        NSString *proposedKey = [NSString stringWithFormat:@"%@.%@", keyPath, modifier];
        if ([[magics valueForKeyPath:keyPath] isKindOfClass:[NSDictionary class]]) {
            if ([magics valueForKeyPath:proposedKey]) {
                targetKey = proposedKey;
                break;
            }
        }
    }

    id finalValue = [magics valueForKeyPath:targetKey];

    NSAssert(lenient || finalValue, @"Expected magic key is missing: %@", keyPath);

    if (finalValue) {
        [lookupCache setObject:finalValue forKey:keyPath];
    }
    return finalValue;
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    return [self objectForKeyPath:keyPath lenient:NO];
}

#pragma mark - Internals

/// Uniquely identify the running version of the app, this will change across builds.
- (NSString *)versionTokenString
{
    NSString *bundleVersionKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleVersionKey];
    NSString *shortVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"%@ (%@)", shortVersionString, bundleVersionKey];
}

- (NSString *)appCacheDirectory
{
    NSArray *search = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *proposedPath = [[search[0]
            stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]]
            stringByAppendingPathComponent:@"com.wearezeta.wazuimagic"];
    if (! [[NSFileManager defaultManager] fileExistsAtPath:proposedPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:proposedPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return proposedPath;
}

- (void)reloadFromDisk
{
    magics = [[NSDictionary alloc] init];
    
    for (NSString *f in preloadedMagicItemNames) {

        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:[f stringByDeletingPathExtension]
                                                                 ofType:[f pathExtension]];
        
        NSDictionary *candidate = [NSDictionary dictionaryWithContentsOfFile:resourcePath];

        if (candidate) {
            preloadedMagicItems[f] = candidate;
        }
    }
}

// recursively deep-merge dictionaries.
- (NSDictionary *)addEntriesToDictionary:(NSDictionary *)d1 fromDictionary:(NSDictionary *)d2
{
    NSMutableDictionary *target = [d1 mutableCopy];
    for (id key in [d2 allKeys]) {
        if ([target[key] isKindOfClass:[NSDictionary class]] && [d2[key] isKindOfClass:[NSDictionary class]]) {
            target[key] = [self addEntriesToDictionary:target[key] fromDictionary:d2[key]];
        } else {
            target[key] = d2[key];
        }
    }
    return target;
}

@end

#pragma mark - Public API - direct value access

@implementation WAZUIMagic (DirectValueAccess)

+ (CGRect)cgRectForIdentifier:(NSString *)identifier
{
    NSArray *array = [self sharedMagic][identifier];

    return CGRectMake([array[0] floatValue],
            [array[1] floatValue],
            [array[2] floatValue],
            [array[3] floatValue]);

}

+ (float)floatForIdentifier:(NSString *)identifier;
{
    NSNumber *number = [[self sharedMagic] numberForIdentifier:identifier];
    return [number floatValue];
}

+ (double)doubleForIdentifier:(NSString *)identifier;
{
    NSNumber *number = [[self sharedMagic] numberForIdentifier:identifier];
    return [number doubleValue];
}

+ (CGFloat)cgFloatForIdentifier:(NSString *)identifier;
{
    if (CGFLOAT_IS_DOUBLE) {
        return [self doubleForIdentifier:identifier];
    } else {
        return [self floatForIdentifier:identifier];
    }
}

+ (NSUInteger)unsignedIntegerForIdentifier:(NSString *)identifier;
{
    NSNumber *number = [[self sharedMagic] numberForIdentifier:identifier];
    return [number unsignedIntegerValue];
}

+ (NSNumber *)numberForIdentifier:(NSString *)identifier
{
    return [[self sharedMagic] numberForIdentifier:identifier];
}

- (NSNumber *)numberForIdentifier:(NSString *)identifier;
{
    NSNumber *number = self[identifier];
    return [number isKindOfClass:[NSNumber class]] ? number : nil;
}

+ (BOOL)boolForIdentifier:(NSString *)identifier;
{
    NSNumber *number = [[self sharedMagic] numberForIdentifier:identifier];
    return [number boolValue];
}

+ (NSString *)stringForIdentifier:(NSString *)identifier
{
    return [[self sharedMagic] stringForIdentifier:identifier];
}

- (NSString *)stringForIdentifier:(NSString *)identifier
{
    NSString *string = self[identifier];
    return [string isKindOfClass:[NSString class]] ? string : nil;
}


@end



@implementation WAZUIMagic (PrivateMethods)

+ (UIColor *)accentColor
{
    WAZUIMagic *m = [self sharedMagic];
    id <WAZUIMagicDelegate> delegate = m.delegate;
    return [delegate accentColor];
}

@end



@implementation WAZUIMagic (iOS)

+ (UIEdgeInsets)edgeInsetsForIdentified:(NSString *)identifier
{
    NSArray *array = [self sharedMagic][identifier];
    
    return UIEdgeInsetsMake(
                            
                            [array[0] floatValue],
                            [array[1] floatValue],
                            [array[2] floatValue],
                            [array[3] floatValue]
                            );
}
@end


@implementation NSNotification (WAZUIMagicObserver)

- (WAZUIMagic *)uiMagic;
{
    return self.object;
}


@end
