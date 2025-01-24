//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@import WireImages;
@import WireTesting;
@import OCMock;


@interface ZMImagePreprocessorTests : ZMTBaseTest

@property (nonatomic) NSOperationQueue *processingQueue;

@end



@implementation ZMImagePreprocessorTests

- (void)setUp
{
    [super setUp];
    self.processingQueue = [[NSOperationQueue alloc] init];
    self.processingQueue.name = [NSString stringWithFormat:@"%@.processingQueue", self.name];
}

- (void)tearDown
{
    self.processingQueue = nil;
    [super tearDown];
}






- (void)testThatItReturnsZeroSizeIfDataIsNotAnImage
{
    NSData *imageData = [self dataForResource:@"Lorem Ipsum" extension:@"txt"];
    AssertEqualSizes([ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData], CGSizeZero);
}

@end
