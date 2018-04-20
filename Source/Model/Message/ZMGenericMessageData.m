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


@import WireProtos;
@import WireUtilities;

#import "ZMGenericMessageData.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString * const ZMGenericMessageDataDataKey = @"data";

NSString * const ZMGenericMessageDataMessageKey = @"message";
NSString * const ZMGenericMessageDataAssetKey = @"asset";

@implementation ZMGenericMessageData

@dynamic data;
@dynamic message;
@dynamic asset;

+ (NSString *)entityName
{
    return @"GenericMessageData";
}

- (ZMGenericMessage *)genericMessage
{
    ZMGenericMessageBuilder *builder = (ZMGenericMessageBuilder *)[[ZMGenericMessage builder] mergeFromData:self.data];
    return [builder build];
}

- (NSSet *)modifiedKeys
{
    return [NSSet set];
}

- (void)setModifiedKeys:(NSSet *)keys
{
    NOT_USED(keys);
}

@end

