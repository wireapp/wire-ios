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


#import "ZMSpellOutSmallNumbersFormatter.h"
#import "MessagingTest.h"



@interface ZMSpellOutSmallNumbersFormatterTests : MessagingTest

@property (nonatomic) ZMSpellOutSmallNumbersFormatter *sut;

@end



@implementation ZMSpellOutSmallNumbersFormatterTests

- (void)setUp
{
    [super setUp];
    self.sut = [[ZMSpellOutSmallNumbersFormatter alloc] init];
    self.sut.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
}

- (void)tearDown
{
    self.sut = nil;
    [super tearDown];
}

- (void)testThatItFormatsNumbers;
{
    XCTAssertEqualObjects([self.sut stringFromNumber:@1], @"one");
    XCTAssertEqualObjects([self.sut stringFromNumber:@2], @"two");
    XCTAssertEqualObjects([self.sut stringFromNumber:@3], @"three");
    XCTAssertEqualObjects([self.sut stringFromNumber:@4], @"four");
    XCTAssertEqualObjects([self.sut stringFromNumber:@5], @"five");
    XCTAssertEqualObjects([self.sut stringFromNumber:@6], @"six");
    XCTAssertEqualObjects([self.sut stringFromNumber:@7], @"seven");
    XCTAssertEqualObjects([self.sut stringFromNumber:@8], @"eight");
    XCTAssertEqualObjects([self.sut stringFromNumber:@9], @"nine");
    
    XCTAssertEqualObjects([self.sut stringFromNumber:@10], @"10");
    XCTAssertEqualObjects([self.sut stringFromNumber:@11], @"11");
}

@end
