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


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ZMAPNSType) {
    ZMAPNSTypeNormal,
    ZMAPNSTypeVoIP
};


@class ZMMobileProvisionParser;

@interface ZMAPNSEnvironment : NSObject

/*!
 @brief There are 4 different application identifiers which map to each of the bundle id's used
 @discussion
 com.wearezeta.zclient.ios-development (dev) - <b>com.wire.dev.ent</b>
 
 com.wearezeta.zclient.ios-internal (internal) - <b>com.wire.int.ent</b>
 
 com.wearezeta.zclient-alpha - <b>com.wire.ent</b>
 
 com.wearezeta.zclient.ios (app store) - <b>com.wire</b>
 
 @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications
 */
@property (nonatomic, readonly) NSString *appIdentifier;


/*!
 @brief There are 4 transport types which depend on the token type and the environment
 @discussion <b>APNS</b> -> ZMAPNSTypeNormal
 
 <b>APNS_VOIP</b> -> ZMAPNSTypeVoIP
 
 <b>APNS_SANDBOX</b> -> ZMAPNSTypeNormal + Sandbox environment
 
 <b>APNS_VOIP_SANDBOX</b> -> ZMAPNSTypeVoIP + Sandbox environment
 
 @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications
*/
- (NSString *)transportTypeForTokenType:(ZMAPNSType)apnsType;
- (NSString *)fallbackForTransportType:(ZMAPNSType)apnsType;

+ (void)setupForProductionWithCertificateName:(NSString *)certName;
+ (void)setupForEnterpriseWithBundleId:(NSString *)bundleId withCertificateName:(NSString *)certName;

@end

@interface ZMAPNSEnvironment(Testing)

- (instancetype)initWithParser:(ZMMobileProvisionParser *)aParser;
- (instancetype)initWithParser:(ZMMobileProvisionParser *)aParser bundleId:(NSString *)bundleId;

@end
