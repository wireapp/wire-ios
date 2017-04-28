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

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZMBackendEnvironmentType) {
    ZMBackendEnvironmentTypeProduction,
    ZMBackendEnvironmentTypeStaging,
};

extern NSString * const ZMBackendEnvironmentTypeKey;

@interface ZMBackendEnvironment : NSObject

@property (nonatomic, readonly) ZMBackendEnvironmentType type;
@property (nonatomic, readonly) NSURL *backendURL;
@property (nonatomic, readonly) NSURL *backendWSURL;
@property (nonatomic, readonly) NSURL *blackListURL;
@property (nonatomic, readonly) NSURL *frontendURL;

/// Register settings for an environment
+ (void)setupEnvironmentOfType:(ZMBackendEnvironmentType)type
               withBackendHost:(NSString *)backendHost
                        wsHost:(NSString *)wsHost
             blackListEndpoint:(NSString *)blackListEndpoint
                  frontendHost:(NSString *)frontendHost;

/// Returns an environment of the given type
+ (instancetype)environmentWithType:(ZMBackendEnvironmentType)type;

- (instancetype)init NS_UNAVAILABLE;

/// Returns an environment of the type specified in the user defaults
- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults;

@end

NS_ASSUME_NONNULL_END
