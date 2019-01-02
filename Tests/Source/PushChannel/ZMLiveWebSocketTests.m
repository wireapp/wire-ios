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
@import WireSystem;
@import WireTesting;

#import "ZMWebSocket.h"


@interface ZMLiveWebSocketTests : ZMTBaseTest <ZMWebSocketConsumer>

@property (nonatomic) NSURL *URL;
@property (nonatomic) ZMWebSocket *sut;
@property (nonatomic) NSMutableArray *receivedData;
@property (nonatomic) NSMutableArray *receivedText;
@property (nonatomic) NSInteger closeCounter;
@property (nonatomic) NetworkSocket *networkSocketMock;
@property (nonatomic) NSInteger openCounter;
@property (nonatomic) dispatch_queue_t queue;


@end



@implementation ZMLiveWebSocketTests

- (void)setUp
{
    [super setUp];
    self.queue = dispatch_queue_create("ZMLiveWebSocketTests", 0);
    self.receivedData = [NSMutableArray array];
    self.receivedText = [NSMutableArray array];
    self.closeCounter = 0;
    self.openCounter = 0;
}

- (void)tearDown
{
    [self.sut close];
    self.sut = nil;
    self.networkSocketMock = nil;
    self.URL = nil;
    self.receivedData = nil;
    self.receivedText = nil;
    self.closeCounter = 0;
    self.openCounter = 0;
    self.queue = NULL;
    [super tearDown];
}



- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithData:(NSData *)data;
{
    XCTAssertEqual(webSocket, self.sut);
//    ZMAssertGroupQueue(self.uiMOC);
    [self.receivedData addObject:data];
}

- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithText:(NSString *)text;
{
    XCTAssertEqual(webSocket, self.sut);
//    ZMAssertGroupQueue(self.uiMOC);
    [self.receivedText addObject:text];
}

- (void)webSocketDidClose:(ZMWebSocket *)webSocket HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *)error;
{
    NOT_USED(response);
    NOT_USED(error);
    XCTAssertEqual(webSocket, self.sut);
//    ZMAssertGroupQueue(self.uiMOC);
    ++self.closeCounter;
}

- (void)webSocketDidCompleteHandshake:(ZMWebSocket *)webSocket HTTPResponse:(NSHTTPURLResponse *)response
{
    NOT_USED(response);
    XCTAssertEqual(webSocket, self.sut);
//    ZMAssertGroupQueue(self.uiMOC);
    ++self.openCounter;
}

- (void)DISABLED_testThatItCanConnectToTheEchoTestServer
{
    NSURL *echoTextServerURL = [NSURL URLWithString:@"ws://zmessaging-ci.local:8083"];
    self.URL = echoTextServerURL;
    self.sut = [[ZMWebSocket alloc] initWithConsumer:self queue:self.queue group:self.fakeUIContext.dispatchGroup url:echoTextServerURL additionalHeaderFields:nil];
    [self.sut sendTextFrameWithString:@"Test Message"];
    
    (void) [self waitOnMainLoopUntilBlock:^BOOL{
        return (0 < self.receivedText.count);
    } timeout:2];
    
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(self.openCounter, 1);
    XCTAssertEqual(self.closeCounter, 1);
    XCTAssertEqual(self.receivedText.count, 1u);
}

- (void)DISABLED_testThatItCanConnectToTheEchoTestServerOverSSL
{
    NSURL *echoTextServerURL = [NSURL URLWithString:@"wss://echo.websocket.org"];
    self.URL = echoTextServerURL;
    self.sut = [[ZMWebSocket alloc] initWithConsumer:self queue:self.queue group:self.fakeUIContext.dispatchGroup url:echoTextServerURL additionalHeaderFields:nil];
    [self.sut sendTextFrameWithString:@"Test Message"];
    
    (void) [self waitOnMainLoopUntilBlock:^BOOL{
        return (0 < self.closeCounter) || (0 < self.receivedText.count);
    } timeout:3];
    
    XCTAssertEqual(self.receivedText.count, 1u);
}

@end
