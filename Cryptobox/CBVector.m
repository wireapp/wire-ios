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


#import "CBVector.h"
#import "CBTypes.h"

#import "CBVector+Internal.h"
#import "cbox.h"



@interface CBVector () {
    CBoxVecRef _vectorBacking;
}

@property (nonatomic, readwrite) NSData *data;

@end

@implementation CBVector

- (void)dealloc
{
    if (_vectorBacking != NULL) {
        cbox_vec_free(_vectorBacking);
        _vectorBacking = NULL;
    }
}

@end



@implementation CBVector (Internal)

- (nonnull instancetype)initWithCBoxVecRef:(nonnull CBoxVecRef)vector
{
    self = [super init];
    if (self) {
        _vectorBacking = vector;
        unsigned long length = cbox_vec_len(vector);
        uint8_t *data = cbox_vec_data(vector);
        self.data = [NSData dataWithBytes:data length:length];
    }
    return self;
}

+ (nonnull instancetype)vectorWithCBoxVecRef:(nonnull CBoxVecRef)vector
{
    return [[self alloc] initWithCBoxVecRef:vector];
}

- (nonnull uint8_t *)dataArray
{
    return cbox_vec_data(_vectorBacking);
}

- (unsigned long)length
{
    return cbox_vec_len(_vectorBacking);
}

@end
