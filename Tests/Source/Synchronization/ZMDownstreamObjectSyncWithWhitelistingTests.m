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

@import ZMCDataModel;

#import "MessagingTest.h"
#import "MockEntity.h"
#import "ZMDownstreamObjectSyncWithWhitelist.h"
#import "ZMSyncOperationSet.h"
#import "ZMTransportResponse.h"
#import "ZMTransportData.h"
#import "ZMTransportRequest.h"
#import "ZMTransportSession.h"
#import "ZMChangeTrackerBootstrap+Testing.h"

static const int FieldValueThatWillTriggerWhitelistingRequirement = 42;

@interface ZMDownstreamObjectSyncWithWhitelistingTests : MessagingTest

@property (nonatomic) id<ZMDownstreamTranscoder> transcoder;
@property (nonatomic) ZMDownstreamObjectSyncWithWhitelist *sut;
@property (nonatomic) NSPredicate *predicateForObjectsToDownload;
@property (nonatomic) NSPredicate *predicateForObjectsRequiringWhitelisting;
@end

@implementation ZMDownstreamObjectSyncWithWhitelistingTests

- (void)setUp {
    [super setUp];
    self.transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMDownstreamTranscoder)];
    
    [self verifyMockLater:self.transcoder];
    
    self.predicateForObjectsToDownload = [NSPredicate predicateWithFormat:@"needsToBeUpdatedFromBackend == YES"];
    self.predicateForObjectsRequiringWhitelisting = [NSPredicate predicateWithFormat:@"field == %d", FieldValueThatWillTriggerWhitelistingRequirement];
    self.sut = [[ZMDownstreamObjectSyncWithWhitelist alloc] initWithTranscoder:self.transcoder
                                                                    entityName:@"MockEntity"
                                                 predicateForObjectsToDownload:self.predicateForObjectsToDownload
                                      predicateForObjectsRequiringWhitelisting:self.predicateForObjectsRequiringWhitelisting
                                                          managedObjectContext:self.testMOC];
}

- (void)tearDown {
    self.transcoder = nil;
    self.sut = nil; 
    self.predicateForObjectsToDownload = nil;
    self.predicateForObjectsRequiringWhitelisting = nil;
    [super tearDown];
}

- (void)makeSureFetchObjectsToDownloadHasBeenCalled;
{
    XCTAssertNil([self.sut nextRequest], @"Make sure -fetchObjectsToDownload has been called.");
}

- (void)testThatOnNextRequestsItDoesNotCreateARequestWhenTheObjectIsNotWhiteListed;
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    entity.field = FieldValueThatWillTriggerWhitelistingRequirement;

    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expect
    [[(id)self.transcoder reject] requestForFetchingObject:OCMOCK_ANY downstreamSync:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequest];
    
    // then
    XCTAssertNil(request);
    [(id)self.transcoder verify];
}

- (void)testThatOnNextRequestsItDoesCreateARequestWhenTheObjectIsWhiteListed;
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    entity.field = FieldValueThatWillTriggerWhitelistingRequirement;
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    ZMTransportRequest *dummyRequest = [ZMTransportRequest requestGetFromPath:@"dummy"];
    
    // expect
    [[[(id)self.transcoder expect] andReturn:dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut];
    
    // when
    [self.sut whiteListObject:entity];
    ZMTransportRequest *request = [self.sut nextRequest];
    
    // then
    XCTAssertEqualObjects(dummyRequest, request);
    [(id) self.transcoder verify];
}

- (void)testThatOnNextRequestsItDoesNotCreateARequestWhenTheObjectIsWhiteListedButNotAdded;
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    
    // expect
    [[(id)self.transcoder reject] requestForFetchingObject:OCMOCK_ANY downstreamSync:OCMOCK_ANY];
    
    // when
    [self.sut whiteListObject:entity];
    ZMTransportRequest *request = [self.sut nextRequest];
    
    // then
    XCTAssertNil(request);
    [(id)self.transcoder verify];
}

- (void)testThatItRemovesAnObjectFromTheWhiteListOnceItIsDownloaded
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    entity.field = FieldValueThatWillTriggerWhitelistingRequirement;
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    ZMTransportRequest *dummyRequest = [ZMTransportRequest requestGetFromPath:@"dummy"];
    
    // expect
    [[[(id)self.transcoder expect] andReturn:dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut];
    
    // when
    [self.sut whiteListObject:entity];
    ZMTransportRequest *request = [self.sut nextRequest];
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{} HTTPstatus:200 transportSessionError:nil]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(dummyRequest, request);
    [(id) self.transcoder verify];
    
    // and expect
    [[(id)self.transcoder reject] requestForFetchingObject:entity downstreamSync:self.sut];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    [self.sut nextRequest];
    
    // then
    [(id) self.transcoder verify];
}

@end
