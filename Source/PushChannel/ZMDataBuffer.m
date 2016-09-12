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


#import "ZMDataBuffer.h"

@interface ZMDataBuffer ()

@property (nonatomic) dispatch_data_t data;

@end


@implementation ZMDataBuffer

- (instancetype)init
{
    self = [super init];
    if(self) {
        void *emptyPointer = NULL;
        self.data = dispatch_data_create(emptyPointer, 0, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    }
    return self;
}

- (void)addData:(dispatch_data_t)data;
{
    NSAssert(self.data != nil, @"_data is nil");
    NSAssert(data != nil, @"data is nil");
    self.data = dispatch_data_create_concat(self.data, data);
}

- (void)clearUntilOffset:(size_t)offset;
{
    size_t size = dispatch_data_get_size(self.data);
    self.data = dispatch_data_create_subrange(self.data, offset, size - offset);
}

- (BOOL)isEmpty;
{
    return (self.data == NULL) || (dispatch_data_get_size(self.data) == 0);
}

@end
