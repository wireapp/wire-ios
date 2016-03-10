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


#import "CBSessionMessage.h"

@interface CBSessionMessage ()

@property (nonatomic, readwrite, nonnull) CBSession *session;
@property (nonatomic, readwrite, nullable) NSData *data;

@end

@implementation CBSessionMessage

- (nonnull instancetype)initWithSession:(nonnull CBSession *)session data:(nullable NSData *)data;
{
    self = [super init];
    if (self) {
        self.session = session;
        self.data = data;
    }
    return self;
}

@end
