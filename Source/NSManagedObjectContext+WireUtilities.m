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


@import WireSystem;
#import "NSManagedObjectContext+WireUtilities.h"
#import "NSObject+DispatchGroups.h"
#import <objc/runtime.h>

static char const AssociatedPendingSaveCountKey;
static NSTimeInterval const PerformWarningTimeout = 10;

@implementation NSManagedObjectContext (ZMSGroupQueue)

- (int)pendingSaveCounter;
{
    NSNumber *n = objc_getAssociatedObject(self,  &AssociatedPendingSaveCountKey);
    return [n intValue];
}
- (void)setPendingSaveCounter:(int)newCounter;
{
    objc_setAssociatedObject(self, &AssociatedPendingSaveCountKey, @(newCounter), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)performGroupedBlock:(dispatch_block_t)block;
{
    NSArray *groups = [self enterAllGroups];
    ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:PerformWarningTimeout];
    [self performBlock:^{
        [tp resetTime];
        block();
        [self leaveAllGroups:groups];
        [tp warnIfLongerThanInterval];
    }];
}

- (void)performGroupedBlockAndWait:(dispatch_block_t)block;
{
    NSArray *groups = [self enterAllGroups];
    ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:PerformWarningTimeout];
    [self performBlockAndWait:^{
        [tp resetTime];
        block();
        [self leaveAllGroups:groups];
        [tp warnIfLongerThanInterval];
    }];
}

- (void)notifyWhenGroupIsEmpty:(dispatch_block_t)block;
{
    // We need to enter & leave all but the first group to make sure that any work added by
    // this method is stil being tracked by the other groups.
    NSArray *groups = [self enterAllButFirstGroup];
    ZMSDispatchGroup *g = self.dispatchGroup;
    VerifyReturn(g != nil);
    [g notifyOnQueue:dispatch_get_global_queue(0, 0) block:^{
        [self performGroupedBlock:block];
        [self leaveAllGroups:groups];
    }];
}

- (ZMSDispatchGroup *)dispatchGroup;
{
    return [self firstGroup];
}

- (NSArray *)executeFetchRequestOrAssert:(NSFetchRequest *)request;
{
    NSError *error;
    NSArray *result = [self executeFetchRequest:request error:&error];
    RequireString(result != nil, "Error in fetching: %lu", (long) error.code);
    return result;
}

@end
