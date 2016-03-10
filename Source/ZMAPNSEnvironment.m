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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#import "ZMAPNSEnvironment.h"
#import "ZMMobileProvisionParser.h"

static NSString * const ZMAPNSEnvironmentSettingsKeyCertificateName         = @"apns_certificate_name";
static NSString * const ZMAPNSEnvironmentSettingsKeySandboxCertificateName  = @"apns_sandbox_certificate_name";

@interface ZMAPNSEnvironment()

@property (nonatomic) ZMMobileProvisionParser *parser;
@property (nonatomic) NSString *bundleId;

@end

@implementation ZMAPNSEnvironment

- (instancetype)init
{
    return [self initWithParser:nil bundleId:nil];
}

- (instancetype)initWithParser:(ZMMobileProvisionParser *)aParser
{
    return [self initWithParser:aParser bundleId:nil];
}

- (instancetype)initWithParser:(ZMMobileProvisionParser *)aParser bundleId:(NSString *)bundleId
{
    self = [super init];
    if (self) {
        self.parser = aParser ?: [[ZMMobileProvisionParser alloc] init];
        self.bundleId = bundleId ?: [[NSBundle mainBundle] bundleIdentifier];
    }
    return self;
}

static NSDictionary *apnsSettings = nil;

+ (void)setupForEnterpriseWithBundleId:(NSString *)bundleId withCertificateName:(NSString *)certName
{
    NSMutableDictionary *settings = [apnsSettings mutableCopy] ?: [NSMutableDictionary new];
    settings[bundleId] = @{
                           ZMAPNSEnvironmentSettingsKeyCertificateName: certName,
                           };
    apnsSettings = [settings copy];
}

+ (void)setupForProductionWithCertificateName:(NSString *)certName
{
    NSMutableDictionary *settings = [apnsSettings mutableCopy] ?: [NSMutableDictionary new];
    settings[@"prod"] = @{
                           ZMAPNSEnvironmentSettingsKeyCertificateName: certName,
                           };
    apnsSettings = [settings copy];
}

- (NSString *)appIdentifier
{
    if (self.parser != nil && self.parser.team == ZMProvisionTeamEnterprise) {
        return apnsSettings[self.bundleId][ZMAPNSEnvironmentSettingsKeyCertificateName];
    }
    else {
        return apnsSettings[@"prod"][ZMAPNSEnvironmentSettingsKeyCertificateName];
    }
}

- (NSString *)transportTypeForTokenType:(ZMAPNSType)apnsType
{
    NSString *transportType = @"APNS";
    if (apnsType == ZMAPNSTypeVoIP) {
        transportType = [transportType stringByAppendingString:@"_VOIP"];
    }
    if (self.parser.APSEnvironment == ZMAPSEnvironmentSandbox) {
        transportType = [transportType stringByAppendingString:@"_SANDBOX"];
    }
    return transportType;
}

- (NSString *)fallbackForTransportType:(ZMAPNSType)apnsType
{
    if (ZMAPNSTypeVoIP != apnsType) {
        return nil;
    }
    
    NSString *transportType = @"APNS";
    if (self.parser.APSEnvironment == ZMAPSEnvironmentSandbox) {
        transportType = [transportType stringByAppendingString:@"_SANDBOX"];
    }
    
    return transportType;
}


+ (NSString *)teamAsString:(ZMProvisionTeam)team
{
    switch (team) {
        case ZMProvisionTeamAppStore:
            return @"AppStore";
        case ZMProvisionTeamEnterprise:
            return @"Enterprise";
        default:
            return @"<Unknown>";
            break;
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p> type %@, parser %@",
            self.class, self,
            [ZMAPNSEnvironment teamAsString:self.parser.team], self.parser];
}

@end
