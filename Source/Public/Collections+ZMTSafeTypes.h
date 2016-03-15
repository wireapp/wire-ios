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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 



#import <Foundation/Foundation.h>

@class ZMEventID;

/// This extension allow to fetch for values that are expected to be of a specific type and
/// will return nil in case the key is not present or the value is not of the expected type
///
/// The @c optional version will not log an error if the key doesn't exist.
@interface NSDictionary (ZMSafeTypes)

- (NSString *)stringForKey:(NSString *)key;
- (NSString *)optionalStringForKey:(NSString *)key;
- (NSNumber *)numberForKey:(NSString *)key;
- (NSNumber *)optionalNumberForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (NSArray *)optionalArrayForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (NSDictionary *)dictionaryForKey:(NSString *)key;
- (NSDictionary *)optionalDictionaryForKey:(NSString *)key;
- (NSUUID *)uuidForKey:(NSString *)key;
- (NSDate *)dateForKey:(NSString *)key;
- (NSUUID *)optionalUuidForKey:(NSString *)key;
- (ZMEventID *)eventForKey:(NSString *)key;
- (ZMEventID *)optionalEventForKey:(NSString *)key;

@end



@interface NSArray (ZMSafeTypes)

/// Returns a copy of the array where all elements are dictionaries. Non-dictionaries are filtered out
- (NSArray *)asDictionaries;

@end
