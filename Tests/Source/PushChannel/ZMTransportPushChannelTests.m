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


@import XCTest;
@import OCMock;
@import WireTesting;

#import "ZMTransportPushChannel.h"
#import "ZMTransportRequestScheduler.h"
#import "ZMPushChannelConnection.h"
#import "ZMTransportSession+internal.h"
#import "ZMAccessToken.h"
#import "WireTransport_ios_tests-Swift.h"


@interface FakePushChannelConnection : NSObject

- (instancetype)initWithURL:(NSURL *)URL consumer:(id<ZMPushChannelConsumer>)consumer queue:(id<ZMSGroupQueue>)queue accessToken:(ZMAccessToken *)accessToken clientID:(NSString *)clientID userAgentString:(NSString *)userAgentString;

@property (nonatomic) NSURL *URL;
@property (nonatomic, weak) id<ZMSGroupQueue> queue;
@property (nonatomic) ZMAccessToken *accessToken;
@property (nonatomic) NSString *clientID;
@property (nonatomic) NSString *userAgentString;
@property (nonatomic) id<ZMPushChannelConsumer> consumer;
@property (nonatomic) BOOL isOpen;
@property (nonatomic) BOOL didCompleteHandshake;

@property (nonatomic) NSUInteger checkConnectionCounter;
@property (nonatomic) NSUInteger closeCounter;

- (void)checkConnection;
- (void)close;
- (void)sendFakeData;

@end

static FakePushChannelConnection *currentFakePushChannelConnection;




@interface ZMTransportPushChannelTests : ZMTBaseTest

@property (nonatomic, copy) NSString *userAgentString;
@property (nonatomic) NSURL *pushChannelURL;
@property (nonatomic) ZMAccessToken *accessToken;
@property (nonatomic) NSString *clientID;

@property (nonatomic) id scheduler;
@property (nonatomic) id consumer;
@property (nonatomic) ZMTransportPushChannel<ZMPushChannelConsumer> *sut;
@property (nonatomic) FakeReachability* reachability;

@end

#pragma mark - Tests

@implementation ZMTransportPushChannelTests

- (void)setUp
{
    [super setUp];

    self.userAgentString = @"pushChannel/1234";
    self.clientID = @"kasd8923jas0p";
    self.accessToken = [OCMockObject niceMockForClass:ZMAccessToken.class];
    self.pushChannelURL = [NSURL URLWithString:@"https://pushchannel.example.com/foo"];
    self.reachability = [[FakeReachability alloc] init];
    self.reachability.mayBeReachable = YES;

    self.scheduler = [OCMockObject niceMockForClass:ZMTransportRequestScheduler.class];
    [[self.scheduler expect] tearDown];
    [[[self.scheduler stub] andCall:@selector(schedulerPerformGroupedBlock:) onObject:self] performGroupedBlock:OCMOCK_ANY];
    [self verifyMockLater:self.scheduler];
    self.sut = (id) [[ZMTransportPushChannel alloc] initWithScheduler:self.scheduler userAgentString:self.userAgentString URL:self.pushChannelURL pushChannelClass:FakePushChannelConnection.class];
    self.sut.keepOpen = YES;
}

- (void)tearDown
{
    currentFakePushChannelConnection.consumer = nil;
    currentFakePushChannelConnection = nil;
    self.sut = nil;
    self.scheduler = nil;
    [super tearDown];
}

- (void)schedulerPerformGroupedBlock:(dispatch_block_t)block;
{
    block();
}

- (void)setupConsumerAndScheduler;
{
    if (self.consumer == nil) {
        self.consumer = [OCMockObject niceMockForProtocol:@protocol(ZMPushChannelConsumer)];
    }
    [self.sut setPushChannelConsumer:self.consumer groupQueue:self.fakeUIContext];
}

- (void)setupConsumerAndStubbedScheduler;
{
    [self setupConsumerAndScheduler];
    [(ZMTransportRequestScheduler *)[self.scheduler stub] addItem:OCMOCK_ANY];
    [(ZMTransportRequestScheduler *)[[self.scheduler stub] andReturn:self.reachability] reachability];
}

- (void)setupClientIDAndAccessToken
{
    [self.sut setClientID:self.clientID];
    [self.sut setAccessToken:self.accessToken];
}

- (void)openPushChannel
{
    [self setupConsumerAndStubbedScheduler];
    [self setupClientIDAndAccessToken];
    [self.sut establishConnection];
}

- (void)testThatItOpensThePushChannelWhenSettingTheConsumer;
{
    // given
    [self setupClientIDAndAccessToken];
    self.consumer = [OCMockObject niceMockForProtocol:@protocol(ZMPushChannelConsumer)];
    
    // expect
    id openPushChannelItem = [[ZMOpenPushChannelRequest alloc] init];
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:openPushChannelItem];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];
    
    // when
    [self.sut setPushChannelConsumer:self.consumer groupQueue:self.fakeUIContext];
}

- (void)testThatItDoesNotOPenThePushChannelIfTheConsumerIsNil
{
    // expect
    id openPushChannelItem = [[ZMOpenPushChannelRequest alloc] init];
    [(ZMTransportRequestScheduler *)[self.scheduler reject] addItem:openPushChannelItem];
    
    // when
    [self.sut setPushChannelConsumer:nil groupQueue:self.fakeUIContext];
}

// TODO: app suspend / resume

- (void)testThatItCreatesAPushChannel;
{
    // given
    [self setupConsumerAndStubbedScheduler];
    [self setupClientIDAndAccessToken];
    
    // when
    [self.sut establishConnection];
    
    // then
    XCTAssertNotNil(currentFakePushChannelConnection);
    XCTAssertEqualObjects(currentFakePushChannelConnection.userAgentString, self.userAgentString);
    NSURL *pushChannelURL = [self.pushChannelURL URLByAppendingPathComponent:@"/await"];
    XCTAssertEqualObjects(currentFakePushChannelConnection.URL, pushChannelURL);
    XCTAssertEqualObjects(currentFakePushChannelConnection.accessToken, self.accessToken);
    XCTAssertEqualObjects(currentFakePushChannelConnection.clientID, self.clientID);
    XCTAssertEqual(currentFakePushChannelConnection.consumer, self.sut);
    id<ZMSGroupQueue> queue = currentFakePushChannelConnection.queue;
    XCTAssertEqual(queue, self.fakeUIContext);
}

- (void)testThatItDoesNotOpenThePushChannelWhenItDoesNotHaveAConsumer;
{
    // given
    [self setupConsumerAndStubbedScheduler];
    [self setupClientIDAndAccessToken];
    
    // when
    [self.sut setPushChannelConsumer:nil groupQueue:nil];
    [self.sut establishConnection];
    
    // then
    XCTAssertNil(currentFakePushChannelConnection);
}

- (void)testThatItClosesThePushChannel
{
    // given
    [self openPushChannel];
    
    // when
    [self.sut closeAndRemoveConsumer];
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
}

- (void)testThatItRemovedTheConsumer
{
    // given
    [self openPushChannel];
    FakePushChannelConnection *pushChannelConnection = currentFakePushChannelConnection;
    
    // expect
    [[self.consumer reject] pushChannel:OCMOCK_ANY didReceiveTransportData:OCMOCK_ANY];
    
    // when
    [self.sut closeAndRemoveConsumer];
    [pushChannelConnection sendFakeData];
    
    // then
    XCTAssertEqual(pushChannelConnection.closeCounter, 1u);
    
}

- (void)testThatItClosesThePushChannel_2
{
    // given
    [self openPushChannel];
    
    // when
    [self.sut close];
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
}

- (void)testThatItCanReopenAfterAClose
{
    // given
    [self openPushChannel];
    id const firstPushChannel = currentFakePushChannelConnection;
    
    // when
    [self.sut close];
    [self.sut establishConnection];
    id const secondPushChannel = currentFakePushChannelConnection;
    
    // then
    XCTAssertNotNil(secondPushChannel);
    XCTAssertNotEqual(firstPushChannel, secondPushChannel);
}

- (void)testThatItOnlyCreatesASinglePushChannel;
{
    // given
    [self openPushChannel];
    id const firstPushChannel = currentFakePushChannelConnection;
    
    // when
    [self.sut establishConnection];
    id const secondPushChannel = currentFakePushChannelConnection;
    
    // then
    XCTAssertEqual(firstPushChannel, secondPushChannel);
}

- (void)testThatItCreatesANewPushChannelIfTheExistingPushChannelIsNotOpen;
{
    // given
    [self openPushChannel];
    id const firstPushChannel = currentFakePushChannelConnection;
    currentFakePushChannelConnection.isOpen = NO;
    
    // when
    [self.sut establishConnection];
    
    // then
    id const secondPushChannel = currentFakePushChannelConnection;
    XCTAssertNotEqual(firstPushChannel, secondPushChannel);
}

- (void)testThatItChecksTheConnectionWhenTheReachabilityChanges_PushChannelOpen;
{
    // given
    [self openPushChannel];
    currentFakePushChannelConnection.isOpen = YES;

    // when
    [self.sut reachabilityDidChange:[OCMockObject niceMockForClass:ZMReachability.class]];
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.checkConnectionCounter, 1u);
}

- (void)testThatItDoesNotCheckTheConnectionWhenTheReachabilityChanges_PushChannelClosed;
{
    // given
    [self openPushChannel];
    currentFakePushChannelConnection.isOpen = NO;

    // when
    [self.sut reachabilityDidChange:[OCMockObject niceMockForClass:ZMReachability.class]];
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.checkConnectionCounter, 0u);
}

- (void)testThatItClosesConnectionWhenPushChannelHandshakeDidNotSucceed
{
    // given
    [self openPushChannel];
    currentFakePushChannelConnection.didCompleteHandshake = NO;
    
    // when
    OCMockObject* reachability = [OCMockObject niceMockForClass:ZMReachability.class];
    [[[reachability stub] andReturnValue:@(YES)] mayBeReachable];
    [[[reachability stub] andReturnValue:@(NO)] oldMayBeReachable];
    [self.sut reachabilityDidChange:(id)reachability];
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
    XCTAssertEqual(currentFakePushChannelConnection.checkConnectionCounter, 0u);
}

- (void)testThatItClosesPushChannelIfTheConsumerHasBeenRemoved
{
    // given
    [self openPushChannel];
    
    // when
    [self.sut setPushChannelConsumer:nil groupQueue:nil];
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
}

- (void)testThatItReopensThePushChannelWhenItCloses;
{
    // expect
    id openPushChannelItem = [[ZMOpenPushChannelRequest alloc] init];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:openPushChannelItem];
    
    // given
    [self setupConsumerAndScheduler];
    [self setupClientIDAndAccessToken];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];

    [self.sut establishConnection];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // expect
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:openPushChannelItem];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];
    [[self.scheduler stub] processCompletedURLResponse:OCMOCK_ANY URLError:nil];

    // when
    [self.sut pushChannelDidClose:(id)currentFakePushChannelConnection withResponse:[OCMockObject niceMockForClass:NSHTTPURLResponse.class]];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItDoesNotReopensThePushChannelWhenItClosesIfThereIsNoConsumer;
{
    // given
    [self openPushChannel];
    
    // expect
    [(ZMTransportRequestScheduler *)[self.scheduler reject] addItem:OCMOCK_ANY]; // no 2nd open
    [[self.scheduler stub] processCompletedURLResponse:OCMOCK_ANY URLError:nil];
    
    // when
    [self.sut setPushChannelConsumer:nil groupQueue:nil];
    [self.sut pushChannelDidClose:(id)currentFakePushChannelConnection withResponse:[OCMockObject niceMockForClass:NSHTTPURLResponse.class]];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItForwardsReceivedDataToItsConsumer
{
    // given
    self.consumer = [OCMockObject mockForProtocol:@protocol(ZMPushChannelConsumer)];
    [self openPushChannel];
    
    // expect
    id<ZMTransportData> fakeData = [OCMockObject niceMockForProtocol:@protocol(ZMTransportData)];
    [[self.consumer expect] pushChannel:(id)currentFakePushChannelConnection didReceiveTransportData:fakeData];
    
    // when
    [self.sut pushChannel:(id)currentFakePushChannelConnection didReceiveTransportData:fakeData];
    [self.consumer verify];
}

- (void)testThatItForwardsDidCloseToItsConsumer
{
    // given
    self.consumer = [OCMockObject mockForProtocol:@protocol(ZMPushChannelConsumer)];
    [self openPushChannel];
    
    // expect
    NSHTTPURLResponse *response = [OCMockObject niceMockForClass:NSHTTPURLResponse.class];
    [[self.consumer expect] pushChannelDidClose:(id)currentFakePushChannelConnection withResponse:response];
    [[self.scheduler stub] processCompletedURLResponse:OCMOCK_ANY URLError:nil];

    // when
    [self.sut pushChannelDidClose:(id)currentFakePushChannelConnection withResponse:response];
    [self.consumer verify];
}

- (void)testThatItForwardsDidOpenToItsConsumer
{
    // given
    self.consumer = [OCMockObject mockForProtocol:@protocol(ZMPushChannelConsumer)];
    [self openPushChannel];
    
    // expect
    NSHTTPURLResponse *response = [OCMockObject niceMockForClass:NSHTTPURLResponse.class];
    [[self.consumer expect] pushChannelDidOpen:(id)currentFakePushChannelConnection withResponse:response];
    [[self.scheduler stub] processCompletedURLResponse:OCMOCK_ANY URLError:nil];
    
    // when
    [self.sut pushChannelDidOpen:(id)currentFakePushChannelConnection withResponse:response];
    [self.consumer verify];
}

- (void)testItForwardsDidOpenResponseToTheScheduler
{
    // given
    [self openPushChannel];
    
    // expect
    NSHTTPURLResponse *response = [OCMockObject niceMockForClass:NSHTTPURLResponse.class];
    [[self.scheduler expect] processCompletedURLResponse:response URLError:nil];
    
    // when
    [self.sut pushChannelDidOpen:(id)currentFakePushChannelConnection withResponse:response];
}

- (void)testItForwardsDidCloseResponseToTheScheduler
{
    // given
    [self openPushChannel];
    
    // expect
    NSHTTPURLResponse *response = [OCMockObject niceMockForClass:NSHTTPURLResponse.class];
    [[self.scheduler expect] processCompletedURLResponse:response URLError:nil];
    
    // when
    [self.sut pushChannelDidClose:(id)currentFakePushChannelConnection withResponse:response];
}

- (void)testItDoesNotForwardANilDidOpenResponseToTheScheduler
{
    // given
    [self openPushChannel];
    
    // expect
    [[self.scheduler reject] processCompletedURLResponse:OCMOCK_ANY URLError:OCMOCK_ANY];
    
    // when
    id response = nil;
    [self.sut pushChannelDidOpen:(id)currentFakePushChannelConnection withResponse:response];
}

- (void)testItDoesNotForwardANilDidCloseResponseToTheScheduler
{
    // given
    [self openPushChannel];
    
    // expect
    [[self.scheduler reject] processCompletedURLResponse:OCMOCK_ANY URLError:OCMOCK_ANY];
    
    // when
    id response = nil;
    [self.sut pushChannelDidClose:(id)currentFakePushChannelConnection withResponse:response];
}

- (void)testThatItNotifiesTheNotworkStateDelegateWhenItReceivesData;
{
    // given
    id networkStateDelegate = [OCMockObject mockForProtocol:@protocol(ZMNetworkStateDelegate)];
    self.sut.networkStateDelegate = networkStateDelegate;
    [self openPushChannel];
    
    // expect
    [[networkStateDelegate expect] didReceiveData];
    
    // when
    id<ZMTransportData> fakeData = [OCMockObject niceMockForProtocol:@protocol(ZMTransportData)];
    [self.sut pushChannel:(id)currentFakePushChannelConnection didReceiveTransportData:fakeData];
    [networkStateDelegate verify];
}

- (void)testThatItSchedulesOpeningThePushChannel
{
    // expect
    id openPushChannelItem = [[ZMOpenPushChannelRequest alloc] init];
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:openPushChannelItem];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];

    // given
    [self setupConsumerAndScheduler];
    [self setupClientIDAndAccessToken];
    [self.sut close];
    
    // expect
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:openPushChannelItem];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];

    // when
    [self.sut attemptToOpen];
}

- (void)testThatItClosesThePushChannelConnectionWhenTheReachabilityChangesFromMobileToWifi
{
    // given
    [self openPushChannel];

    // when
    self.reachability.oldIsMobileConnection = YES;
    self.reachability.isMobileConnection = NO;
    [self.sut reachabilityDidChange:self.reachability];
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
}


- (void)testThatItDoesNotCloseThePushChannelConnectionWhenTheReachabilityNetworkDoesNotChange
{
    // given
    [self openPushChannel];
    
    // we set the connection to mobile
    self.reachability.isMobileConnection = YES;
    [self.sut reachabilityDidChange:self.reachability];
    
    // when
    self.reachability.isMobileConnection = YES;
    [self.sut reachabilityDidChange:self.reachability];

    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 0u);
}

- (void)testThatItDoesNotCloseThePushChannelConnectionWhenTheReachabilityChangesFromWifiToMobile
{
    // given
    [self openPushChannel];

    // when
    self.reachability.oldIsMobileConnection = NO;
    self.reachability.isMobileConnection = YES;
    [self.sut reachabilityDidChange:self.reachability];

    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 0u);
}

- (void)testThatItOpensThePushChannel_whenKeepOpenIsSetToTrue
{
    // given
    self.sut.keepOpen = NO;
    [self setupConsumerAndScheduler];
    [self setupClientIDAndAccessToken];
    
    
    // expect
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:OCMOCK_ANY];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];

    // when
    self.sut.keepOpen = YES;
}

- (void)testThatItOpensThePushChannel_whenAccessTokenIsSet
{
    // given
    [self setupConsumerAndScheduler];
    [self.sut setClientID:self.clientID];
    
    // expect
    
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:OCMOCK_ANY];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];

    // when
    [self.sut setAccessToken:self.accessToken];
}

- (void)testThatItOpensThePushChannel_whenClientIDIsSet
{
    // given
    [self setupConsumerAndScheduler];
    [self.sut setAccessToken:self.accessToken];
    
    // expect
    
    [(ZMTransportRequestScheduler *)[self.scheduler expect] addItem:OCMOCK_ANY];
    [(ZMTransportRequestScheduler *)[[self.scheduler expect] andReturn:self.reachability] reachability];

    // when
    [self.sut setClientID:self.clientID];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItClosesThePushChannel_whenKeepOpenIsSetToFalse
{
    // given
    [self openPushChannel];
    self.sut.keepOpen = YES;
    
    // when
    self.sut.keepOpen = NO;
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
}

- (void)testThatItClosesThePushChannel_whenAccessTokenIsCleared
{
    // given
    [self openPushChannel];
    
    // when
    self.sut.accessToken = nil;
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
}

- (void)testThatItClosesThePushChannel_whenClienIDIsCleared
{
    // given
    [self openPushChannel];
    
    // when
    self.sut.clientID = nil;
    
    // then
    XCTAssertEqual(currentFakePushChannelConnection.closeCounter, 1u);
}

@end



@implementation FakePushChannelConnection

- (instancetype)initWithURL:(NSURL *)URL consumer:(id<ZMPushChannelConsumer>)consumer queue:(id<ZMSGroupQueue>)queue accessToken:(ZMAccessToken *)accessToken clientID:(NSString *)clientID userAgentString:(NSString *)userAgentString;
{
    self = [super init];
    if (self) {
        self.URL = URL;
        self.consumer = consumer;
        self.queue = queue;
        self.accessToken = accessToken;
        self.clientID = clientID;
        self.userAgentString = userAgentString;
        self.isOpen = YES;
    }
    currentFakePushChannelConnection = self;
    return self;
}

- (void)checkConnection;
{
    self.checkConnectionCounter++;
}

- (void)close;
{
    self.closeCounter++;
    self.isOpen = NO;
}

- (void)sendFakeData
{
    [self.consumer pushChannel:(ZMPushChannelConnection *)self didReceiveTransportData:@[]];
}

@end
