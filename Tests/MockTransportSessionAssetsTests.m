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


#import "MockTransportSessionTests.h"

@interface MockTransportSessionAssetsTests : MockTransportSessionTests

@end

@implementation MockTransportSessionAssetsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatInsertingAnAssetCreatesOne;
{
    NSUUID *assetID = [NSUUID createUUID], *assetToken = [NSUUID createUUID];
    NSData *imageData = [self mediumJPEGData];
    
    __block MockAsset *asset = nil;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        asset = [session insertAssetWithID:assetID assetToken:assetToken assetData:imageData contentType:@"image/jpeg"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertNotNil(asset);
    XCTAssertTrue([asset.identifier isEqualToString:assetID.transportString]);
    XCTAssertTrue([asset.token isEqualToString:assetToken.transportString]);
    XCTAssertTrue([asset.data isEqualToData:imageData]);
    XCTAssertTrue([asset.contentType isEqualToString:@"image/jpeg"]);
}

@end
