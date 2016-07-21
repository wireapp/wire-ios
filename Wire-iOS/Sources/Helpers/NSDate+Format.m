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


#import "NSDate+Format.h"
#import <objc/runtime.h>

static NSDateFormatter *extendedFormaterForDate;
static NSDateFormatter *extendedFormatterForTime;

@implementation NSDate (Format)

- (NSString *)extendedFormat
{
    
    if(! extendedFormaterForDate){
        
        extendedFormaterForDate = [[NSDateFormatter alloc] init];
        [extendedFormaterForDate setDateStyle:NSDateFormatterFullStyle];
        [extendedFormaterForDate setTimeStyle:NSDateFormatterNoStyle];
    }
    
    if(! extendedFormatterForTime){
        
        extendedFormatterForTime = [[NSDateFormatter alloc] init];
        [extendedFormatterForTime setDateStyle:NSDateFormatterNoStyle];
        [extendedFormatterForTime setTimeStyle:NSDateFormatterShortStyle];
    }
	

	NSString *dateString = [extendedFormaterForDate stringFromDate:self];
	NSString *timeString = [extendedFormatterForTime stringFromDate:self];
    
    return [NSString stringWithFormat:@"%@ ∙ %@", dateString, timeString];
}

@end
