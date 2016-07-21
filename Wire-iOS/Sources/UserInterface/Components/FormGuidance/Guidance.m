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


#import "Guidance.h"



@implementation Guidance

+ (instancetype)guidanceWithTitle:(NSString *)title explanation:(NSString *)explanation
{
    Guidance *guidance = [[Guidance alloc] init];
    guidance.title = title;
    guidance.explanation = explanation;
    return guidance;
}

+ (instancetype)guidanceWitType:(GuidanceType)guidanceType
{
    Guidance *guidance = [[Guidance alloc] init];
    guidance.guidanceType = guidanceType;
    return guidance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.guidanceType = GuidanceTypeError;
    }
    return self;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p> title = %@, explanation %@, type = %d", [self class], self, self.title, self.explanation, (int) self.guidanceType];
}

@end



@implementation Guidance (Debug)

+ (instancetype)debugGuidance
{
    Guidance *debugGuidance = [Guidance guidanceWithTitle:@"A VERY LONG TITLE - A VERY LONG TITLE - A VERY LONG TITLE - A VERY LONG TITLE - A VERY LONG TITLE - A VERY LONG TITLE - A VERY LONG TITLE" explanation:@"A VERY LONG EXPLANATION - A VERY LONG EXPLANATION - A VERY LONG EXPLANATION -A VERY LONG EXPLANATION -A VERY LONG EXPLANATION -A VERY LONG EXPLANATION"];

    return debugGuidance;
}

@end
