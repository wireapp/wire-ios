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

#import "ZMAccentColorValidator.h"
#import "ZMAccentColor.h"

@implementation ZMAccentColorValidator

ZM_EMPTY_ASSERTING_INIT()

+ (BOOL)validateValue:(inout id *)ioValue error:(out NSError ** __unused)outError
{
    if ((*ioValue == nil) ||
        ([*ioValue intValue] < (int) ZMAccentColorMin) ||
        ((int) ZMAccentColorMax < [*ioValue intValue]))
    {
        ZMAccentColor color = (ZMAccentColor) (((int16_t) ZMAccentColorMin) +
                                               ((int16_t) arc4random_uniform((u_int32_t) (ZMAccentColorMax - ZMAccentColorMin))));
        *ioValue = @(color);
    }
    return YES;
}

@end
