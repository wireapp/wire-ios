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

@class ZMURLSession;
@import WireUtilities;



/// Switch between instances of ZMURLSession. When switching existing tasks in that session are cancelled.
@interface ZMURLSessionSwitch : NSObject <TearDownCapable>

/// The currently selected session
@property (nonatomic, readonly) ZMURLSession *currentSession;

/// The foreground session
@property (nonatomic, readonly) ZMURLSession *foregroundSession;
@property (nonatomic, readonly) ZMURLSession *backgroundSession;
@property (nonatomic, readonly) ZMURLSession *voipSession;

@property (nonatomic, readonly) NSArray <ZMURLSession *> *allSessions;

- (instancetype)initWithForegroundSession:(ZMURLSession *)foregroundSession backgroundSession:(ZMURLSession *)backgroundSession voipSession:(ZMURLSession *)voipSession;
- (instancetype)initWithForegroundSession:(ZMURLSession *)foregroundSession backgroundSession:(ZMURLSession *)backgroundSession voipSession:(ZMURLSession *)voipSession sessionCancelTimerClass:(nullable Class)sessionCancelTimerClass NS_DESIGNATED_INITIALIZER;

- (void)tearDown;

- (void)switchToForegroundSession;
- (void)switchToBackgroundSession;

@end

NS_ASSUME_NONNULL_END
