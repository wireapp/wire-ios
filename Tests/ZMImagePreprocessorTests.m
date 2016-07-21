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


@import zimages;
@import ZMTesting;
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

- (void)testThatItCanCalculateTheSizeOfAnImage
{
    NSURL *imageURL = [self fileURLForResource:@"medium" extension:@"jpg"];
    AssertEqualSizes([ZMImagePreprocessor sizeOfPrerotatedImageAtURL:imageURL], CGSizeMake(1612, 1072));
}

- (void)testThatItReturnsZeroSizeIfFileIsNotAnImage
{
    NSURL *imageURL = [self fileURLForResource:@"Lorem Ipsum" extension:@"txt"];
    AssertEqualSizes([ZMImagePreprocessor sizeOfPrerotatedImageAtURL:imageURL], CGSizeZero);
}

- (void)testThatItReturnsTheRotatedSizeForImagesWithATIFFOrientation
{
    NSURL *imageURL;
    imageURL = [self fileURLForResource:@"exif_orientation/ExifOrientation3" extension:@"jpg"];
    XCTAssertNotNil(imageURL);
    CGSize orientation3Size = [ZMImagePreprocessor sizeOfPrerotatedImageAtURL:imageURL];
    AssertEqualSizes(orientation3Size, CGSizeMake(1240, 1754));
    imageURL = [self fileURLForResource:@"exif_orientation/ExifOrientation6" extension:@"jpg"];
    XCTAssertNotNil(imageURL);
    CGSize orientation6Size = [ZMImagePreprocessor sizeOfPrerotatedImageAtURL:imageURL];
    AssertEqualSizes(orientation6Size, CGSizeMake(1240, 1754));
    imageURL = [self fileURLForResource:@"exif_orientation/ExifOrientation8" extension:@"jpg"];
    XCTAssertNotNil(imageURL);
    CGSize orientation8Size = [ZMImagePreprocessor sizeOfPrerotatedImageAtURL:imageURL];
    AssertEqualSizes(orientation8Size, CGSizeMake(1240, 1754));
}

- (void)testThatItReturnsTheRotatedSizeForImagesWithTIFFOrientation5;
{
    NSDictionary *properties = @{@"ColorModel": @"RGB",
                                 @"DPIHeight": @72,
                                 @"DPIWidth": @72,
                                 @"Depth": @8,
                                 @"Orientation": @5,
                                 @"PixelHeight": @600,
                                 @"PixelWidth": @450,
                                 @"ProfileName": @"Generic RGB Profile",
                                 @"{Exif}": @{
                                         @"PixelXDimension": @450,
                                         @"PixelYDimension": @600,
                                         },
                                 @"{JFIF}": @{
                                         @"DensityUnit": @1,
                                         @"JFIFVersion": @[@1, @0, @1],
                                         @"XDensity": @72,
                                         @"YDensity": @72,
                                         },
                                 @"{TIFF}": @{
                                         @"Orientation": @5,
                                         @"ResolutionUnit": @2,
                                         @"XResolution": @72,
                                         @"YResolution": @72,
                                         },
                                 };
    CGSize expected = {600, 450};
    XCTAssertTrue(CGSizeEqualToSize([ZMImagePreprocessor imageSizeFromProperties:properties], expected));
}

- (void)testThatItReturnsTheRotatedSizeForImagesWithTIFFOrientation7;
{
    NSDictionary *properties = @{@"ColorModel": @"RGB",
                                 @"DPIHeight": @72,
                                 @"DPIWidth": @72,
                                 @"Depth": @8,
                                 @"Orientation": @7,
                                 @"PixelHeight": @450,
                                 @"PixelWidth": @600,
                                 @"ProfileName": @"Generic RGB Profile",
                                 @"{Exif}": @{
                                         @"PixelXDimension": @600,
                                         @"PixelYDimension": @450,
                                         },
                                 @"{JFIF}": @{
                                         @"DensityUnit": @1,
                                         @"JFIFVersion": @[@1, @0, @1],
                                         @"XDensity": @72,
                                         @"YDensity": @72,
                                         },
                                 @"{TIFF}": @{
                                         @"Orientation": @7,
                                         @"ResolutionUnit": @2,
                                         @"XResolution": @72,
                                         @"YResolution": @72,
                                         },
                                 };
    CGSize expected = {450, 600};
    XCTAssertTrue(CGSizeEqualToSize([ZMImagePreprocessor imageSizeFromProperties:properties], expected));
}

- (void)testThatItReturnsZeroSizeIfFileDoesNotExist
{
    NSURL *imageURL = [NSURL fileURLWithPath:@"/goo/asdf"];
    AssertEqualSizes([ZMImagePreprocessor sizeOfPrerotatedImageAtURL:imageURL], CGSizeZero);
}

- (void)testThatItCanCalculateTheSizeOfAnImageFromData
{
    NSData *imageData = [self dataForResource:@"medium" extension:@"jpg"];
    AssertEqualSizes([ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData], CGSizeMake(1612, 1072));
}


- (void)testThatItReturnsZeroSizeIfDataIsNotAnImage
{
    NSData *imageData = [self dataForResource:@"Lorem Ipsum" extension:@"txt"];
    AssertEqualSizes([ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData], CGSizeZero);
}

@end



@implementation ZMImagePreprocessorTests (MediumAndPreviewGeneration)

- (void)testThatBothRepresentationsAreGenerated
{
    return; // 1 TODO REFACTOR -> implement and make ZMAssetTranscoder use it
    
    // given
    NSData *imageData = [self dataForResource:@"rotated with orientation 3" extension:@"jpg"];
    XCTAssertNotNil(imageData);
    ZMImagePreprocessor *sut = [[ZMImagePreprocessor alloc] initWithImageData:imageData processingQueue:self.processingQueue];
    
    __block NSData *mediumData;
    __block BOOL done = NO;
    id handler = [OCMockObject mockForProtocol:@protocol(ZMImagePreprocessorHandler)];
    [[handler expect] imagePreprocessor:sut didProducePreviewData:[OCMArg checkWithBlock:^BOOL(NSData *data) {mediumData = data; return YES;}]];
    [[handler expect] imagePreprocessor:sut didProduceMediumData:[OCMArg checkWithBlock:^BOOL(NSData *data) {mediumData = data; return YES;}]];
    [[[handler expect] andDo:^(__unused NSInvocation *i){ done = YES; }] imagePreprocessorDidComplete:sut];
    
    // when
    [sut generateRepresentationsWithResultHandler:handler callbackQueue:[NSOperationQueue mainQueue]];
    
    // then
    XCTAssert([self waitOnMainLoopUntilBlock:^BOOL{
        return done;
    } timeout:1]);
}

@end
