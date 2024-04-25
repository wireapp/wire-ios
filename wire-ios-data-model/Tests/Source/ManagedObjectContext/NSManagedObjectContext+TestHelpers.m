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

#import "NSManagedObjectContext+TestHelpers.h"
#import "ZMBaseManagedObjectTest.h"

@implementation NSManagedObjectContext (TestHelpers)

- (void)performGroupedBlockThenWaitForReasonableTimeout:(dispatch_block_t)block;
{
    NSTimeInterval timeInterval2 = [ZMBaseManagedObjectTest timeToUseForOriginalTime:100];
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:timeInterval2];

    __block BOOL done = NO;
    [self performGroupedBlock:^{
        block();
        done = YES;
    }];
    
    while (! done && (0. < [end timeIntervalSinceNow])) {
        [ZMBaseManagedObjectTest performRunLoopTick];
    }
    NSAssert(done, @"Wait failed");
}

@end
