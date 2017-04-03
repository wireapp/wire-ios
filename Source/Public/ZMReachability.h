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
@import WireSystem;

@protocol ZMReachabilityObserver;



@interface ZMReachability : NSObject

/// Calls to the observer will always happen on the specified @c observerQueue . All work will be added to the @c group
- (instancetype)initWithServerNames:(NSArray *)names observer:(id<ZMReachabilityObserver>)observer queue:(NSOperationQueue *)observerQueue group:(ZMSDispatchGroup *)group;

- (void)tearDown;

/// When this returns @c NO some of the named servers are definetly not reachable.
/// In reverse, this returns @c YES when there's a chance that we may be able to connect to at least one of the named servers.
@property (atomic, readonly) BOOL mayBeReachable;
@property (atomic, readonly) BOOL isMobileConnection;

@end



@protocol ZMReachabilityObserver <NSObject>

- (void)reachabilityDidChange:(ZMReachability *)reachability;

@end


@protocol ZMNetworkStateDelegate <NSObject>

- (void)didReceiveData;
- (void)didGoOffline;

@end

NS_ASSUME_NONNULL_END
