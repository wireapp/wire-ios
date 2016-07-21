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


#import "DefaultIntegerClusterizer.h"

IntRange DefaultRangesRanges[] = {{1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 10}, {11, 15}, {16, 20}, {21, 30}, {31, 40}, {41, 50}};
RangeSet DefaultRanges = {DefaultRangesRanges, 11};

IntRange MessageRangesRanges[] = {{1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 10}, {11, 15}, {16, 20}, {21, 30}, {31, 40}, {41, 50}, {51, 60}, {61, 70}, {71, 80}, {81, 100}};
RangeSet MessageRanges = {MessageRangesRanges, 15};

IntRange ParticipantRangesRanges[] = {{3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 10}, {11, 20}};
RangeSet ParticipantRanges = {ParticipantRangesRanges, 6};

IntRange FileSizeRangesRanges[] = {{1, 5}, {6, 10}, {11, 15}, {16, 20}, {21, 25}};
RangeSet FileSizeRanges = {FileSizeRangesRanges, 5};

@implementation DefaultIntegerClusterizer

+ (instancetype)defaultClusterizer
{
    static DefaultIntegerClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [DefaultIntegerClusterizer new];
        clusterizer.rangeSet = DefaultRanges;
    });

    return clusterizer;
}

+ (instancetype)messageClusterizer
{
    static DefaultIntegerClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [DefaultIntegerClusterizer new];
        clusterizer.rangeSet = MessageRanges;
    });
    
    return clusterizer;
}

+ (instancetype)participantClusterizer
{
    static DefaultIntegerClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [DefaultIntegerClusterizer new];
        clusterizer.rangeSet = ParticipantRanges;
    });
    
    return clusterizer;
}

+ (instancetype)fileSizeClusterizer
{
    static DefaultIntegerClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [DefaultIntegerClusterizer new];
        clusterizer.rangeSet = FileSizeRanges;
    });
    
    return clusterizer;
}

- (NSString *)clusterizeValue:(id)value
{
    if (! [value isKindOfClass:[NSNumber class]]) {
        return @"?";
    }

    int intval = [value intValue];

    return [self clusterizeInteger:intval];
}

- (NSString *)clusterizeInteger:(NSInteger)intval
{
    if (intval < self.rangeSet.ranges[0].start) {
        return [NSString stringWithFormat:@"%ld", (long)intval];
    }

    for (unsigned int i = 0; i < self.rangeSet.rangesCount; i ++) {
        if (self.rangeSet.ranges[i].start <= intval && intval <= self.rangeSet.ranges[i].end) {
            return [NSString stringWithFormat:@"%d-%d", self.rangeSet.ranges[i].start, self.rangeSet.ranges[i].end];
        }
    }

    return [NSString stringWithFormat:@"%d+", self.rangeSet.ranges[self.rangeSet.rangesCount - 1].end + 1];
}

@end
