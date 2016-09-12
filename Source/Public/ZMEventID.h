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

/// An event ID returned by the back-end
@interface ZMEventID : NSValue

+ (nullable instancetype)eventIDWithString:(NSString *)string;
+ (instancetype)eventIDWithMajor:(uint64_t)major minor:(uint64_t)minor;
- (instancetype)initWithMajor:(uint64_t)major minor:(uint64_t)minor;

- (NSComparisonResult)compare:(ZMEventID *)otherEventID;
- (BOOL)isEqualToEventID:(ZMEventID *)otherEventID;
- (NSString *)transportString;
+ (instancetype)earliestOfEventID:(ZMEventID *)eventID1 and:(ZMEventID *)eventID2;
+ (instancetype)latestOfEventID:(ZMEventID *)eventID1 and:(ZMEventID *)eventID2;

@property (nonatomic, readonly) uint64_t major;
@property (nonatomic, readonly) uint64_t minor;

@end



/// Used to store in database
@interface ZMEventID (SerializingToData)

+ (nullable ZMEventID *)decodeFromData:(NSData *)data;
- (NSData *)encodeToData;

@end

NS_ASSUME_NONNULL_END
