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


@import zimages;
@import ZMTesting;

#import "NSOperationQueue+Helpers.h"

static NSString const * TypeJPEG = @"image/jpeg";

@interface ZMImageDownsampleOperationTests : ZMTBaseTest
@end



@implementation ZMImageDownsampleOperationTests



//- (void)testAssertImageDataIsEqualPerformance;
//{
//    NSData *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation4" extension:@"jpg"];
//    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation4_unrotated_preview" extension:@"jpg"];
//
//    [self measureBlock:^{
//        @autoreleasepool {
//            ImageComparator *comp = [[ImageComparator alloc] initWithImageDataA:outputData imageDataB:expectedData];
//            [comp calculateDifference];
//        }
//    }];
//}


- (ZMImageDownsampleOperation *)mediumImageDataForInputFileName:(NSString *)name extension:(NSString *)ext
{
    NSData *inputData = [self dataForResource:name extension:ext];
    return [self mediumImageDataForInputData:inputData];
}

- (ZMImageDownsampleOperation *)mediumImageDataForInputData:(NSData *)inputData
{
    return [self downsampleResultForInputData:inputData downsampleType:ZMImageDownsampleTypeMedium];
}

- (ZMImageDownsampleOperation *)previewImageDataForInputFileName:(NSString *)name extension:(NSString *)ext
{
    NSData *inputData = [self dataForResource:name extension:ext];
    return [self previewImageDataForInputData:inputData];
}

- (ZMImageDownsampleOperation *)previewImageDataForInputData:(NSData *)inputData
{
    return [self downsampleResultForInputData:inputData downsampleType:ZMImageDownsampleTypePreview];
}

- (ZMImageDownsampleOperation *)smallProfileImageDataForInputFileName:(NSString *)name extension:(NSString *)ext
{
    NSData *inputData = [self dataForResource:name extension:ext];
    return [self smallProfileImageDataForInputData:inputData];
}

- (ZMImageDownsampleOperation *)smallProfileImageDataForInputData:(NSData *)inputData
{
    return [self downsampleResultForInputData:inputData downsampleType:ZMImageDownsampleTypeSmallProfile];
}


- (ZMImageDownsampleOperation *)downsampleResultForInputData:(NSData *)inputData downsampleType:(ZMImageDownsampleType)downSampleType
{
    ZMImageLoadOperation *loadOperation = [[ZMImageLoadOperation alloc] initWithImageData:inputData];
    
    ZMImageDownsampleOperation *sut = [[ZMImageDownsampleOperation alloc] initWithLoadOperation:loadOperation downsampleType:downSampleType];
    
    NSOperationQueue *queue = [NSOperationQueue serialQueueWithName:self.name];
    
    [queue addOperation:loadOperation];
    [queue addOperation:sut];
    
    [queue waitUntilAllOperationsAreFinishedWithTimeout:2];
    return sut;
}




@end



@implementation ZMImageDownsampleOperationTests (MediumImage)


- (void)testThatItGeneratesAMediumRepresentation
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"DownsampleImageRotated3" extension:@"jpg"];

    
    // then
    XCTAssertNotNil(outputData);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotGeneratesAMediumRepresentationWhenCanceled
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:invalidData];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
}

- (void)testThatItDoesNotGeneratesAMediumRepresentationFromInvalidImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"Lorem Ipsum" extension:@"txt"];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
}


- (void)testThatItScalesTheImage
{
    // Compression test case (1): Pixel dimensions too big
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"1900x1500" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"1900x1500_medium" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssertEqualObjects(outputData.properties.mimeType, TypeJPEG);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUnrotatesAndScalesDownAnImageThatHasTooLargePixelDimensionsAndIsRotated
{
    // Compression test case (1): Pixel dimensions too big with rotated image
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"rotated with orientation 6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"scaled and unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));

    
}

- (void)testMediumDownsamplePerformance;
{
    [self measureMetrics:[[self class] defaultPerformanceMetrics] automaticallyStartMeasuring:NO forBlock:^{
        @autoreleasepool {
            NSData *inputData = [self dataForResource:@"rotated with orientation 6" extension:@"jpg"];
            [self startMeasuring];
            ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:inputData];
            [self stopMeasuring];
            (void) outputData;
        }
    }];
}


- (void)testThatItUnrotatesAnImage {
    // Compression test case (2): Pixel dimensions and byte OK, rotated

    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"ExifOrientation6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"UnrotatedImage" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));

}

- (void)testThatItUsesTheOriginalDataWhenTheImageIsSufficientlySmallAndNotRotated
{
    // Compression test case (3): Pixel dimensions and byte OK, not rotated
    
    // given
    NSData *inputData = [self dataForResource:@"cat_999x633" extension:@"jpg"];
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:inputData];
    
    // then
    XCTAssertNotNil(outputData);
    AssertImageDataIsEqual(outputData.downsampleImageData, inputData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));

}


- (void)testThatItRecompressesAnImageThatHasSmallPixelDimensionsButFileSizeThatIsTooBigToJPEG
{
    // In this case, initial recompression doesn't help much, so that it finally compresses the image as jpeg

    // Compression test case (4): Pixel dimension OK, byte size too big,
    // -> recompressed in original format and still too big, recompressed as JPEG
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"Church_1MB" extension:@"png"];

    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"Church_1MB_medium" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItUnrotatesAnImageThatIsRotatedAndHasSmallPixelDimensionsButTooBigFileSize
{
    // Compression test case (5): Pixel dimension OK, byte size too big,
    // -> recompressed in original format, rotated

    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"Ceiling_rotated" extension:@"jpg"];

    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"Ceiling_recompressed_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));

}


// XXX WONTFIX IMAGES add test cases for case (6): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and did not change that much, not rotated
// XXX WONTFIX IMAGES add test cases for case (7): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and it helped

- (void)testThatItDoesNotCompressAnImageFurtherIfOriginalFormatCompressionIsGoodEnough
{
    // Compression test case (8): Pixel dimension OK, byte size too big,
    // ->recompressed in original and it did not change that much, not rotated
    
    // given
    NSData *inputData = [self dataForResource:@"Church_900KB" extension:@"jpg"];
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:inputData];

    // then
    XCTAssertNotNil(outputData);
    AssertImageDataIsEqual(inputData, outputData.downsampleImageData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItUnrotatesAnImageThatIsIsSmallEnoughWhenRecompressedAsJPEG
{
    // Compression test case (9): Pixel dimensions OK, byte size too big,
    // ->recompressed in original format and it did not change that much, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"Church_900KB_rotated" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"Church_900KB_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}



// C.f. <https://irfanview-forum.de/showthread.php?t=9715> for test images
- (void)testThatItDoesNotChangeAnImageWithOrientation1
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation1" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation1" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItReorientatesAnImageWithOrientation2
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation2" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation2_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAnImageWithOrientation3
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation3" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation3_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAnImageWithOrientation4
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation4" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation4_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAnImageWithOrientation5
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation5" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation5_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAnImageWithOrientation6
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation6_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAnImageWithOrientation7
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation7" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation7_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAnImageWithOrientation8
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"exif_orientation/ExifOrientation8" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation8_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItReturnsTheOriginalImageDataForAGIFThatsFailyLarge;
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"colorful-mess" extension:@"gif"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"colorful-mess" extension:@"gif"];
    AssertEqualData(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

@end




@implementation ZMImageDownsampleOperationTests (PreviewImage)

- (void)testThatItDoesNotGeneratesAPreviewRepresentationFromInvalidImage
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageLoadOperation *loadOperation = [[ZMImageLoadOperation alloc] initWithImageData:invalidData];
    ZMImageDownsampleOperation *sut = [[ZMImageDownsampleOperation alloc] initWithLoadOperation:loadOperation downsampleType:ZMImageDownsampleTypePreview];
    
    // when
    NSOperationQueue *queue = [NSOperationQueue serialQueueWithName:self.name];
    [queue addOperation:loadOperation];
    [queue waitUntilAllOperationsAreFinishedWithTimeout:2];
    
    // then
    XCTAssertNil(sut.downsampleImageData);
}

- (void)testThatItGeneratesAPreviewRepresentation
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"1900x1500" extension:@"jpg"];
    
    
    // then
    XCTAssertNotNil(outputData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotGeneratesAPreviewRepresentationWhenCanceled
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputData:invalidData];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotGenerateAPreviewRepresentationFromInvalidImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"Lorem Ipsum" extension:@"txt"];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
}


- (void)testThatItScalesThePreviewImage
{
    // Compression test case (1): Pixel dimensions too big
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"1900x1500" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"1900x1500_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUnrotatesAndScalesDownAPreviewImageThatHasTooLargePixelDimensionsAndIsRotated
{
    // Compression test case (1): Pixel dimensions too big with rotated image
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"rotated with orientation 6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"scaled and unrotated preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItUnrotatesAPreviewImage
{
    // Compression test case (2): Pixel dimensions and byte OK, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"ExifOrientation6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"UnrotatedImage_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUsesTheOriginalDataWhenThePreviewImageIsSufficientlySmallAndNotRotated
{
    // Compression test case (3): Pixel dimensions and byte OK, not rotated
    
    // given
    NSData *inputData = [self dataForResource:@"abstract_27x16" extension:@"jpg"];
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputData:inputData];
    
    // then
    XCTAssertNotNil(outputData);
    AssertImageDataIsEqual(outputData.downsampleImageData, inputData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

// XXX WONTFIX IMAGES
// This test behaves differently on iOS and OS X. Need to figure out why.
//
//- (void)testThatItReencodesAnImageToJpegEvenIfItIsOtherwiseFine
//{
//    // given
//    NSData *outputData = [self previewImageDataForInputFileName:@"abstract_27x16" extension:@"png"];
//    
//    // then
//    XCTAssertNotNil(outputData);
//    NSData *expectedData = [self dataForResource:@"abstract_27x16png" extension:@"jpg"];
//    AssertImageDataIsEqual(outputData, expectedData);
//}



- (void)testThatItRecompressesAPreviewImageThatHasSmallPixelDimensionsButFileSizeThatIsTooBigToJPEG
{
    // In this case, initial recompression doesn't help much, so that it finally compresses the image as jpeg
    
    // Compression test case (4): Pixel dimension OK, byte size too big,
    // -> recompressed in original format and still too big, recompressed as JPEG
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"Church_1MB" extension:@"png"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"Church_1MB_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItUnrotatesAPreviewImageThatIsRotatedAndHasSmallPixelDimensionsButTooBigFileSize
{
    // Compression test case (5): Pixel dimension OK, byte size too big,
    // -> recompressed in original format, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"Ceiling_rotated" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"Ceiling_recompressed_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


// XXX WONTFIX IMAGES add test cases for case (6): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and did not change that much, not rotated
// XXX WONTFIX IMAGES add test cases for case (7): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and it helped

// XXX WONTFIX IMAGES find a fitting image for this test case
//- (void)testThatItDoesNotCompressAPreviewImageFurtherIfOriginalFormatCompressionIsGoodEnough
//{
//    // Compression test case (8): Pixel dimension OK, byte size too big,
//    // ->recompressed in original and it did not change that much, not rotated
//
//    // given
//    NSData *inputData = [self dataForResource:@"Church_900KB" extension:@"jpg"];
//    NSData *outputData = [self previewImageDataForInputData:inputData];
//    
//    // then
//    XCTAssertNotNil(outputData);
//    AssertImageDataIsEqual(inputData, outputData);
//}

- (void)testThatItUnrotatesAPreviewImageThatIsIsSmallEnoughWhenRecompressedAsJPEG
{
    // Compression test case (9): Pixel dimensions OK, byte size too big,
    // ->recompressed in original format and it did not change that much, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"Church_900KB_rotated" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"Church_900KB_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}



// C.f. <https://irfanview-forum.de/showthread.php?t=9715> for test images
- (void)testThatItDoesNotChangeAPreviewImageWithOrientation1
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation1" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation1_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItReorientatesAPreviewImageWithOrientation2
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation2" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation2_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAPreviewImageWithOrientation3
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation3" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation3_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAPreviewImageWithOrientation4
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation4" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation4_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItReorientatesAPreviewImageWithOrientation5
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation5" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation5_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAPreviewImageWithOrientation6
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation6_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAPreviewImageWithOrientation7
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation7" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation7_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItReorientatesAPreviewImageWithOrientation8
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"exif_orientation/ExifOrientation8" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"exif_orientation/ExifOrientation8_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

@end



@implementation ZMImageDownsampleOperationTests (SmallProfile)

- (void)testThatItDoesNotGeneratesASmallProfileRepresentationFromInvalidImage
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageLoadOperation *loadOperation = [[ZMImageLoadOperation alloc] initWithImageData:invalidData];
    ZMImageDownsampleOperation *sut = [[ZMImageDownsampleOperation alloc] initWithLoadOperation:loadOperation downsampleType:ZMImageDownsampleTypeSmallProfile];
    
    // when
    NSOperationQueue *queue = [NSOperationQueue serialQueueWithName:self.name];
    [queue addOperation:loadOperation];
    [queue waitUntilAllOperationsAreFinishedWithTimeout:2];
    
    // then
    XCTAssertNil(sut.downsampleImageData);
}

- (void)testThatItGeneratesASmallProfileRepresentationALandscapeImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self smallProfileImageDataForInputFileName:@"1900x1500_medium" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"1900x1500_smallProfile" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatProfile);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItGeneratesASmallProfileRepresentationFromAPortraitImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self smallProfileImageDataForInputFileName:@"Mersey00036992" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"Mersey00036992_smallProfile" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatProfile);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItGeneratesASmallProfileRepresentationFromATinyImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self smallProfileImageDataForInputFileName:@"tiny" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"tiny_smallProfile" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatProfile);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

@end
