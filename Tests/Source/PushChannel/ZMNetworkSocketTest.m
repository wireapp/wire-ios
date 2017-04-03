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
@import WireTesting;
@import WireSystem;

#import "ZMNetworkSocket.h"



@interface ZMNetworkSocketTest : ZMTBaseTest <ZMNetworkSocketDelegate>

@property (nonatomic) ZMNetworkSocket *sut;
@property (nonatomic) NSMutableData *dataRead;
@property (nonatomic) NSInteger openCounter;
@property (nonatomic) NSInteger closeCounter;
@property (nonatomic) dispatch_queue_t queue;

@end


@implementation ZMNetworkSocketTest

- (void)setUp
{
    [super setUp];
    self.openCounter = 0;
    self.closeCounter = 0;
    self.dataRead = [NSMutableData dataWithCapacity:16 * 1024];
    self.queue = dispatch_queue_create([self.name UTF8String], 0);
}

- (void)tearDown
{
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    self.queue = nil;
    if(self.sut != nil) {
        XCTAssertEqual(self.closeCounter, 1);
    }
    self.sut = nil;
    [super tearDown];
}

//- (BOOL)checkThatWeCanRetrieveHTTPSURL:(NSURL *)url ZM_MUST_USE_RETURN
//{
//    self.sut = [[ZMNetworkSocket alloc] initWithURL:url delegate:self delegateQueue:self.queue group:self.syncMOC.dispatchGroup];
//    XCTAssertNotNil(self.sut);
//    BOOL success = [self checkThatWeCanRetrieveHTTPSURL:url withNetworkSocket:self.sut];
//    [self.sut close];
//    WaitForAllGroupsToBeEmpty(0.5);
//    return success;
//}

- (BOOL)checkThatWeCanRetrieveHTTPSURL:(NSURL *)url withNetworkSocket:(ZMNetworkSocket *)socket ZM_MUST_USE_RETURN
{
    
    NSString *requestHeader = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
                               "Accept: */*\r\n"
                               "Accept-Encoding: gzip, deflate, compress\r\n"
                               "Host: %@\r\n"
                               //"User-Agent: Mozilla/5.0 \r\n"
                               "\r\n"
                               "\r\n", url.path, url.host ];
    NSData *requestData = [requestHeader dataUsingEncoding:NSUTF8StringEncoding];
    
    dispatch_data_t request = dispatch_data_create(requestData.bytes, requestData.length, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    // when
    [socket open];
    [socket writeDataToNetwork:request];
    [self expectationForNotification:@"ZMNetworkSocketTest" object:nil handler:^BOOL(NSNotification *notification) {
        NOT_USED(notification);
        return YES;
    }];
    
    // then
    if(![self waitForCustomExpectationsWithTimeout:10 handler:nil]) {
        NSLog(@"Failed to contact server at URL: %@",url);
        return NO;
    }
    CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(NULL, NO);
    if(!CFHTTPMessageAppendBytes(message, self.dataRead.bytes, (CFIndex) self.dataRead.length)) {
        CFRelease(message);
        return NO;
    }
    CFIndex status = CFHTTPMessageGetResponseStatusCode(message);
    if(!(status >= 100 && status < 400)) {
        CFRelease(message);
        NSLog(@"Unexpected return status %ld for URL: %@", status, url);
        return NO;
    }
    NSString *statusLine =CFBridgingRelease(CFHTTPMessageCopyResponseStatusLine(message));
    CFRelease(message);
    if(![statusLine hasPrefix:@"HTTP/1.1"]) {
        NSLog(@"Unexpected response status line from %@: %@", url, statusLine);
        return NO;
    }
    if(self.openCounter != 1) {
        return NO;
    }
    
    return YES;
}

// this test is disabled as it seems to fail on the CI server 100% for some reason
//- (void)DISABLED_testThatItRetrievesAWellKnownHomepage
//{
//    // given
//    NSArray *urls = @[
//                      @"https://www.apple.com/",
//                      @"https://www.google.com/",
//                      @"https://de.wikipedia.org/",
//                      @"https://www.amazon.de/",
//                      ];
//    
//    // this test tries different urls, with a sleep in between. If one service/the network is down, hopefully the next one will work after that delay
//    __block size_t failures = 0;
//    for(NSString *url in urls) {
//        __block BOOL success = NO;
//        [self performIgnoringZMLogError:^{
//            if([self checkThatWeCanRetrieveHTTPSURL:[NSURL URLWithString:url]]) {
//                NSLog(@"Successfully connected to %@", url);
//                success = YES;
//                return;
//            }
//            NSLog(@"Fail to retrieve %@", url);
//            [NSThread sleepForTimeInterval:failures*3];
//            ++failures;
//
//        }];
//        if(success) {
//            return;
//        }
//    }
//    XCTFail(@"Failed to retrieve any URL");
//}

// this test is disabled as it seems to fail on the CI server 100% for some reason
//- (void)DISABLED_testThatItFailsWhenRetrieveingFromANonexistingServer;
//{
//    NSURL *url = [NSURL URLWithString:@"https://127.0.0.1:38973/this-does-not-exist"];
//    [self performIgnoringZMLogError:^{
//        self.sut = [[ZMNetworkSocket alloc] initWithURL:url delegate:self delegateQueue:self.queue group:self.syncMOC.dispatchGroup];
//    
//        XCTAssertNotNil(self.sut);
//        
//        NSString *requestHeader = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
//                                   "Accept: */*\r\n"
//                                   "Accept-Encoding: gzip, deflate, compress\r\n"
//                                   "Host: %@\r\n"
//                                   "User-Agent: ZMNetworkSocket\r\n"
//                                   "\r\n"
//                                   "\r\n", url.path, url.host ];
//        NSData *requestData = [requestHeader dataUsingEncoding:NSUTF8StringEncoding];
//        
//        dispatch_data_t request = dispatch_data_create(requestData.bytes, requestData.length, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
//        
//        // when
//
//        [self.sut open];
//        [self.sut writeDataToNetwork:request];
//        [self expectationForNotification:@"ZMNetworkSocketClosed" object:nil handler:^BOOL(NSNotification *notification) {
//            NOT_USED(notification);
//            return YES;
//        }];
//    
//    
//        // then
//        XCTAssertTrue([self waitForCustomExpectationsWithTimeout:5 handler:nil]);
//        XCTAssertEqual(self.dataRead.length, 0u);
//        XCTAssertEqual(self.openCounter, 0);
//        XCTAssertEqual(self.closeCounter, 1);
//    }];
//}

- (void)networkSocket:(ZMNetworkSocket *)socket didReceiveData:(dispatch_data_t)data;
{
    XCTAssertEqual(socket, self.sut);
    [self.dataRead appendData:(NSData *) data];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZMNetworkSocketTest" object:self.dataRead];
}

- (void)networkSocketDidClose:(ZMNetworkSocket *)socket;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZMNetworkSocketClosed" object:socket];
    XCTAssertEqual(socket, self.sut);
    self.closeCounter++;
}

- (void)networkSocketDidOpen:(ZMNetworkSocket *)socket
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZMNetworkSocketOpened" object:socket];
    XCTAssertEqual(socket, self.sut);
    self.openCounter++;
}

@end
