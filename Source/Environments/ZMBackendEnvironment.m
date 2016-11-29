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


@import ZMCSystem;

#import "ZMBackendEnvironment.h"
#import "ZMBackendEnvironment+Testing.h"
#import "ZMTLogging.h"

static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK;

NSString * const ZMBackendEnvironmentTypeKey = @"ZMBackendEnvironmentType";

static NSString *const BackendEnvironmentTypeDefault = @"default";
static NSString *const BackendEnvironmentTypeProduction = @"production";
static NSString *const BackendEnvironmentTypeStaging = @"staging";
static NSString *const BackendEnvironmentTypeEdge = @"edge";

static NSString * const ZMBackendEnvironmentSettingsKeyBackendHost          = @"env_backend_host";
static NSString * const ZMBackendEnvironmentSettingsKeyBackendWSHost        = @"env_backend_ws_host";
static NSString * const ZMBackendEnvironmentSettingsKeyBlacklistEndpoint    = @"env_blacklist_endpoint";
static NSString * const ZMBackendEnvironmentSettingsKeyFrontendHost         = @"env_frontend_host";

static NSString * const ProductionBackendHost = @"prod-nginz-https.wire.com";
static NSString * const ProductionBackendWSHost = @"prod-nginz-ssl.wire.com";
static NSString * const ProductionFrontendHost = @"wire.com";

static NSString * const StagingBackendHost = @"staging-nginz-https.zinfra.io";
static NSString * const StagingBackendWSHost = @"staging-nginz-ssl.zinfra.io";
static NSString * const StagingFrontendHost = @"staging-website.zinfra.io";

static NSString * const EdgeBackendHost = @"edge-nginz-https.zinfra.io";
static NSString * const EdgeBackendWSHost = @"edge-nginz-ssl.zinfra.io";
static NSString * const EdgeFrontendHost = @"edge-website.zinfra.io";

static NSString * const ZMBlacklistEndPoint_IOS = @"clientblacklist.wire.com/prod/ios";
static NSString * const ZMBlacklistEndPoint_IOS_Staging = @"clientblacklist.wire.com/staging/ios";
static NSString * const ZMBlacklistEndPoint_IOS_Edge = @"clientblacklist.wire.com/edge/ios";


static dispatch_queue_t environmentIsolationQueue()
{
    static dispatch_queue_t isolationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isolationQueue = dispatch_queue_create("ZMBackendEnvironment.isolation", DISPATCH_QUEUE_CONCURRENT);
    });
    return isolationQueue;
}

static NSMutableDictionary *environmentSettings()
{
    static NSMutableDictionary *settings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [NSMutableDictionary dictionary];
    });
    return settings;
}

static void setSettingsForEnvironmentType(ZMBackendEnvironmentType key, NSDictionary *value)
{
    dispatch_barrier_async(environmentIsolationQueue(), ^{
        environmentSettings()[@(key)] = value;
    });
}

@interface ZMBackendEnvironment ()

@property (nonatomic) ZMBackendEnvironmentType type;
@property (nonatomic) NSString *bundleID;

@end


@implementation ZMBackendEnvironment

- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults
{
    self = [super init];
    if (self) {
        NSString *environmentKey = [defaults stringForKey:ZMBackendEnvironmentTypeKey];
        self.type = [self environmentForKey:environmentKey];
        ZMLogInfo(@"Environment initialized to %@", [ZMBackendEnvironment environmentTypeAsString:self.type]);
    }
    return self;
}

+ (void)setupEnvironmentOfType:(ZMBackendEnvironmentType)type
               withBackendHost:(NSString *)backendHost
                        wsHost:(NSString *)wsHost
             blackListEndpoint:(NSString *)blackListEndpoint
                  frontendHost:(NSString *)frontendHost
{
    setSettingsForEnvironmentType(type,  @{
                                           ZMBackendEnvironmentSettingsKeyBackendHost: [self urlForBackendHostString: backendHost],
                                           ZMBackendEnvironmentSettingsKeyBackendWSHost: [self urlForBackendHostString: wsHost],
                                           ZMBackendEnvironmentSettingsKeyBlacklistEndpoint: [self urlForBackendHostString: blackListEndpoint],
                                           ZMBackendEnvironmentSettingsKeyFrontendHost: [self urlForBackendHostString: frontendHost]
                                           });
}

+ (NSDictionary *)environmentSettingsForType:(ZMBackendEnvironmentType)type
{
    __block NSDictionary *value;
    dispatch_sync(environmentIsolationQueue(), ^{
        value = [environmentSettings() objectForKey:@(type)];
    });
    
    if (value == nil) {
        value = [[self defaultEnvironmentSettings] objectForKey:@(type)];
    }
    
    return value;
}

+ (NSDictionary *)defaultEnvironmentSettings
{
    static NSDictionary *settings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = @{
                     @(ZMBackendEnvironmentTypeProduction) : @{
                             ZMBackendEnvironmentSettingsKeyBackendHost: [self urlForBackendHostString:ProductionBackendHost],
                             ZMBackendEnvironmentSettingsKeyBackendWSHost: [self urlForBackendHostString:ProductionBackendWSHost],
                             ZMBackendEnvironmentSettingsKeyFrontendHost: [self urlForBackendHostString:ProductionFrontendHost],
                             ZMBackendEnvironmentSettingsKeyBlacklistEndpoint: [self urlForBackendHostString:ZMBlacklistEndPoint_IOS]
                             },
                     @(ZMBackendEnvironmentTypeStaging) : @{
                             ZMBackendEnvironmentSettingsKeyBackendHost: [self urlForBackendHostString:StagingBackendHost],
                             ZMBackendEnvironmentSettingsKeyBackendWSHost: [self urlForBackendHostString:StagingBackendWSHost],
                             ZMBackendEnvironmentSettingsKeyFrontendHost: [self urlForBackendHostString:StagingFrontendHost],
                             ZMBackendEnvironmentSettingsKeyBlacklistEndpoint: [self urlForBackendHostString:ZMBlacklistEndPoint_IOS_Staging]
                             },
                     @(ZMBackendEnvironmentTypeEdge) : @{
                             ZMBackendEnvironmentSettingsKeyBackendHost: [self urlForBackendHostString:EdgeBackendHost],
                             ZMBackendEnvironmentSettingsKeyBackendWSHost: [self urlForBackendHostString:EdgeBackendWSHost],
                             ZMBackendEnvironmentSettingsKeyFrontendHost: [self urlForBackendHostString:EdgeFrontendHost],
                             ZMBackendEnvironmentSettingsKeyBlacklistEndpoint: [self urlForBackendHostString:ZMBlacklistEndPoint_IOS_Edge]
                             }
                     };
    });
    return settings;
}

+ (NSString *)environmentTypeAsString:(ZMBackendEnvironmentType)type
{
    switch (type) {
        case ZMBackendEnvironmentTypeProduction:
            return @"Production";
            break;
        case ZMBackendEnvironmentTypeStaging:
            return @"Staging";
            break;
        case ZMBackendEnvironmentTypeEdge:
            return @"Edge";
            break;
        default:
            return @"<Unknown>";
            break;
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p> type %@",
            self.class, self,
            [ZMBackendEnvironment environmentTypeAsString:self.type]];
}

- (ZMBackendEnvironmentType)environmentForKey:(NSString *)key
{
    key = key.lowercaseString;
    if (key == nil || [key isEqualToString:BackendEnvironmentTypeDefault]) {
        return ZMBackendEnvironmentTypeProduction;
    }
    if ([key isEqualToString:BackendEnvironmentTypeProduction]) {
        return ZMBackendEnvironmentTypeProduction;
    }
    if ([key isEqualToString:BackendEnvironmentTypeStaging]) {
        return ZMBackendEnvironmentTypeStaging;
    }
    if ([key isEqualToString:BackendEnvironmentTypeEdge]) {
        return ZMBackendEnvironmentTypeEdge;
    }
    
    ZMLogError(@"Error: %@ is not a valid environment - switching to default (production) environment", key);
    return ZMBackendEnvironmentTypeProduction;
}

- (instancetype)init
{
    return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithType:(ZMBackendEnvironmentType)type
{
    self = [super init];
    if (self) {
        self.type = type;
    }
    return self;
}

+ (instancetype)environmentWithType:(ZMBackendEnvironmentType)type;
{
    return [[ZMBackendEnvironment alloc] initWithType:type];
}

- (NSURL *)blackListURL
{
    return [ZMBackendEnvironment environmentSettingsForType:self.type][ZMBackendEnvironmentSettingsKeyBlacklistEndpoint];
}

- (NSURL *)backendURL
{
    return [ZMBackendEnvironment environmentSettingsForType:self.type][ZMBackendEnvironmentSettingsKeyBackendHost];
}

- (NSURL *)backendWSURL
{
    return [ZMBackendEnvironment environmentSettingsForType:self.type][ZMBackendEnvironmentSettingsKeyBackendWSHost];
}

- (NSURL *)frontendURL
{
    return [ZMBackendEnvironment environmentSettingsForType:self.type][ZMBackendEnvironmentSettingsKeyFrontendHost];
}

+ (NSURL *)urlForBackendHostString:(NSString *)hostString
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"https";
    NSMutableArray *pathComponents = [[hostString componentsSeparatedByString:@"/"] mutableCopy];
    components.host = [pathComponents firstObject];
    [pathComponents replaceObjectAtIndex:0 withObject:@""];
    components.path = [pathComponents componentsJoinedByString:@"/"];
    return components.URL;
}

@end
