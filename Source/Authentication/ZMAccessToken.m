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



#import "ZMAccessToken.h"
@import WireSystem;



@interface ZMAccessToken ()

@property (nonatomic) NSString *token;
@property (nonatomic) NSString *type;
@property (nonatomic) NSDate *expirationDate;

@end


@implementation ZMAccessToken
{

}
- (instancetype)initWithToken:(NSString *)token type:(NSString *)type expiresInSeconds:(NSUInteger)seconds;
{
    self = [super init];
    if (self) {
        self.token = token;
        self.type = type;
        self.expirationDate = [NSDate dateWithTimeIntervalSinceNow:seconds];
    }

    return self;
}

- (NSDictionary *)httpHeaders
{
    return @{@"Authorization" : [NSString stringWithFormat:@"%@ %@", self.type, self.token]};
}

- (NSString *)debugDescription;
{
    return [NSString stringWithFormat:@"<%@: %p> type: %@, token: %@, expires in %lld seconds",
            self.class, self,
            self.type, self.token,
            llround([self.expirationDate timeIntervalSinceNow])];
}

@end
