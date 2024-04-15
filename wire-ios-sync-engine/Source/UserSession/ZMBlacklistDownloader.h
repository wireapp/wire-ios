//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@import Foundation;
@import WireUtilities;

@protocol ZMApplication;
@protocol BackendEnvironmentProvider;

@interface ZMBlacklistDownloader : NSObject <TearDownCapable>

/// Creates a downloader that will download the blacklist file at regular intervals and invokes the completion handler on the main queue when a blacklist is available
- (instancetype)initWithDownloadInterval:(NSTimeInterval)downloadInterval
                             environment:(id<BackendEnvironmentProvider>)environment
                           proxyUsername:(NSString *)proxyUsername
                           proxyPassword:(NSString *)proxyPassword
                                readyForRequests:(BOOL)readyForRequests
                            workingGroup:(ZMSDispatchGroup *)workingGroup
                             application:(id<ZMApplication>)application
                           minTLSVersion:(NSString *)minTLSVersion
                       completionHandler:(void (^)(NSString *minVersion, NSArray *excludedVersions))completionHandler;

@end
