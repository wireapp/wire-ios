//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
#import "NSObject+DispatchGroups.h"

@import WireSystem;

@interface ZMDispatchGroupQueue : NSObject <ZMSGroupQueue>

@property (nonatomic, readonly) dispatch_queue_t queue;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

/// Performs a block and wait for completion.
/// @note: The block is not retained after its execution. This means that if the queue
/// is not running (e.g. blocked by a deadlock), the block and all its captured variables
/// will be retained, otherwise it will eventually be released.
/// @attention: Be *very careful* not to create deadlocks.
- (void)performGroupedBlockAndWait:(dispatch_block_t)block;

@end
