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


@import XCTest;
@import ZMTransport;
@import ZMCSystem;
@import ZMTesting;
@import OCMock;

#import "ZMURLSession.h"
#import "ZMURLSession+Internal.h"
#import "ZMTemporaryFileListForBackgroundRequests.h"
#import "Fakes.h"

@interface ZMURLSessionTests : ZMTBaseTest <ZMURLSessionDelegate, ZMTimerClient>

@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) ZMURLSession<NSURLSessionDataDelegate, NSURLSessionDownloadDelegate> *sut;
@property (nonatomic) NSURLSessionTask *taskA;
@property (nonatomic) NSURLSessionTask *taskB;

@property (nonatomic) NSURLRequest *URLRequestA;
@property (nonatomic) NSURLRequest *URLRequestB;

@property (nonatomic) NSUInteger receivedDataCount;
@property (nonatomic) NSMutableArray *receivedResponses;
@property (nonatomic) NSMutableArray *completedTasks;
@property (nonatomic) NSMutableArray *firedTimers;

@end



static NSString * const TaskKey = @"response";
static NSString * const RequestKey = @"request";
static NSString * const DataKey = @"data";



@implementation ZMURLSessionTests

- (void)setUp
{
    [super setUp];
    
    self.receivedResponses = [NSMutableArray array];
    self.completedTasks = [NSMutableArray array];
    self.firedTimers = [NSMutableArray array];
    self.receivedDataCount = 0;
    
    self.queue = [NSOperationQueue zm_serialQueueWithName:self.name];
    self.sut = (id) [ZMURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];

    self.URLRequestA = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://a.exmaple.com/"]];
    self.URLRequestB = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://b.exmaple.com/"]];
    self.taskA = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:nil];
    self.taskB = [self.sut taskWithRequest:self.URLRequestB bodyData:nil transportRequest:nil];
}

- (void)tearDown
{
    self.queue = nil;
    self.receivedResponses = nil;
    self.completedTasks = nil;
    self.receivedDataCount = 0;
    self.firedTimers = nil;

    [self.sut tearDown];
    self.sut = nil;
    [super tearDown];
}

- (void)timerDidFire:(ZMTimer *)timer;
{
    [self.firedTimers addObject:timer];
}

- (void)URLSession:(ZMURLSession *)URLSession dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;
{
    XCTAssertEqual(URLSession, self.sut);
    NOT_USED(dataTask);
    [self.receivedResponses addObject:response];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSessionDidReceiveData:(ZMURLSession *)URLSession;
{
    XCTAssertEqual(URLSession, self.sut);
    ++self.receivedDataCount;
}

- (void)URLSession:(ZMURLSession *)URLSession taskDidComplete:(NSURLSessionTask *)task transportRequest:(ZMTransportRequest *)transportRequest responseData:(NSData *)responseData;
{
    XCTAssertEqual(URLSession, self.sut);
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    if (task != nil) {
        arguments[TaskKey] = task;
    }
    if (transportRequest != nil) {
        arguments[RequestKey] = transportRequest;
    }
    if (responseData != nil) {
        arguments[DataKey] = responseData;
    }
    [self.completedTasks addObject:arguments];
}

- (void)testThatItPassesTheRequestToTheCompletionMethod;
{
    // given
    ZMTransportRequest *request = [ZMTransportRequest requestGetFromPath:@"/some/path/"];
    NSURLSessionTask *task = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:request];
    
    // when
    [self.sut URLSession:self.sut.backingSession task:task didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqual(d[RequestKey], request);
}

- (void)testThatItCancelsTheTimerWhenTheTaskCompletes;
{
    // given
    ZMTimer *timer = [ZMTimer timerWithTarget:self];
    
    // when
    [self.sut setTimeoutTimer:timer forTask:self.taskA];
    [timer fireAfterTimeInterval:0.05];
    [self.sut URLSession:self.sut.backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    [self spinMainQueueWithTimeout:0.1];
    XCTAssertEqual(self.firedTimers.count, 0u);
    [timer cancel];
}

- (void)testThatItCanAppendDataToADataTask;
{
    // when
    id backingSession = self.sut.backingSession;
    [self.sut URLSession:backingSession dataTask:(id) self.taskA didReceiveData:[NSData dataWithBytes:(uint8_t[]){0xfe} length:1]];
    [self.sut URLSession:backingSession dataTask:(id) self.taskA didReceiveData:[NSData dataWithBytes:(uint8_t[]){0xda} length:1]];
    [self.sut URLSession:backingSession dataTask:(id) self.taskA didReceiveData:[NSData dataWithBytes:(uint8_t[]){0xbe} length:1]];
    [self.sut URLSession:backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSData *expectedData = [NSData dataWithBytes:(uint8_t[]){0xfe, 0xda, 0xbe} length:3];
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqualObjects(d[DataKey], expectedData);
}

- (void)testThatItCanDownloadDataWithADownloadTask;
{
    // when
    NSURL *dataLocation = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    dataLocation = [dataLocation URLByAppendingPathComponent:@"downloadTask-test-data"];
    NSData * const data = [NSData dataWithBytes:(uint8_t[]){0xfe, 0xda, 0xbe} length:3];
    XCTAssert([data writeToURL:dataLocation options:0 error:NULL]);
    
    id backingSession = self.sut.backingSession;
    [self.sut URLSession:backingSession downloadTask:(id) self.taskA didFinishDownloadingToURL:dataLocation];
    XCTAssert([[NSFileManager defaultManager] removeItemAtURL:dataLocation error:NULL]);
    
    [self.sut URLSession:backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqualObjects(d[DataKey], data);
}

- (void)testThatItCancelsAllTimers;
{
    // given
    @autoreleasepool {
        ZMTimer *timerA = [ZMTimer timerWithTarget:(id) self];
        ZMTimer *timerB = [ZMTimer timerWithTarget:(id) self];
        [self.sut setTimeoutTimer:timerA forTask:self.taskA];
        [self.sut setTimeoutTimer:timerB forTask:self.taskB];
        
        // when
        [self.sut cancelAndRemoveAllTimers];
    }
    WaitForAllGroupsToBeEmpty(0.5);
    // This will fail with "ZMTimer was not cleaned up correctly" unless cancel has been called.
}

@end



@implementation ZMURLSessionTests (Delegate)

- (void)testThatItCallsTheDelegateWhenItReceivesAResponse;
{
    // given
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://foo.example.com"] MIMEType:@"application/binary" expectedContentLength:1234 textEncodingName:@"utf8"];
    XCTestExpectation *e = [self expectationWithDescription:@"completion handler"];
    
    // when
    [self.sut URLSession:self.sut.backingSession dataTask:(id) self.taskA didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [e fulfill];
        (void) disposition;
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    XCTAssertEqual(self.receivedResponses.count, 1u);
    XCTAssertEqual(self.receivedResponses.firstObject, response);
}

- (void)testThatItCallsTheDelegateWhenItReceivesData;
{
    // given
    NSData *data = [NSData dataWithBytes:(uint8_t[]){0xfe, 0xda, 0xbe} length:3];
    XCTAssertEqual(self.receivedDataCount, 0u);
    
    // when
    [self.sut URLSession:self.sut.backingSession dataTask:(id) self.taskA didReceiveData:data];
    
    // then
    XCTAssertEqual(self.receivedDataCount, 1u);
}

- (void)testThatItCallsTheDelegateWhenATaskCompletes;
{
    // given
    XCTAssertEqual(self.completedTasks.count, 0u);
    
    // when
    [self.sut URLSession:self.sut.backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqual(d[TaskKey], self.taskA);
}

- (void)testThatItAddsAuthenticationTokenToRedirect
{
    // given
    NSString *initialURL = @"http://example.com/initial";
    NSString *finalURL = @"http://example.com/final";
    NSString *tokenValue = @"abc123456";
    NSString *tokenKey = @"Authorization";
    
    NSMutableURLRequest *originalRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:initialURL]];
    [originalRequest setValue:tokenValue forHTTPHeaderField:tokenKey];
    NSURLSessionDataTask *originalTask = [self.sut.backingSession dataTaskWithRequest:originalRequest];
    
    NSURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:finalURL]];
    
    XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"Completion handler invoked"];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"foo"] statusCode:302 HTTPVersion:@"1.1" headerFields:@{}];
    
    // when
    [self.sut URLSession:self.sut.backingSession
                    task:originalTask
willPerformHTTPRedirection:response
              newRequest:newRequest
       completionHandler:^(NSURLRequest * _Nullable req) {
        XCTAssertEqualObjects(req.URL, [NSURL URLWithString:finalURL]);
        XCTAssertEqualObjects(req.allHTTPHeaderFields[tokenKey], tokenValue);
        
        [completionHandlerCalled fulfill];
    }];
    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0]);
}

@end



@implementation ZMURLSessionTests (TaskGeneration)

- (void)setupMockBackgroundSession
{    
    self.sut = (id) [ZMURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate:self delegateQueue:self.queue];
    self.sut.backingSession = [OCMockObject niceMockForClass:NSURLSession.class];
    
    [[[(id)self.sut.backingSession stub] andReturn:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.name]] configuration];
    
    [(id) self.sut.backingSession verify];
}

- (void)setupBackgroundSession;
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.name];
    [self.sut tearDown];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];
    
    self.sut = (id) [ZMURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.queue];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];
    
    self.URLRequestA = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://a.exmaple.com/"]];
    self.URLRequestB = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://b.exmaple.com/"]];
    self.taskA = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:nil];
    self.taskB = [self.sut taskWithRequest:self.URLRequestB bodyData:nil transportRequest:nil];
}

- (void)testThatItDetectsAForegroundSession;
{
    XCTAssertFalse(self.sut.isBackgroundSession);
}

- (void)testThatItDetectsABackgroundSession;
{
    // given
    [self setupBackgroundSession];
    
    // then
    XCTAssertTrue(self.sut.isBackgroundSession);
}

- (void)testThatItCreatesADataTask;
{
    // given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://baz.example.com/1/"]];
    
    // when
    NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:nil transportRequest:nil];
    
    // then
    XCTAssertNotNil(task);
    XCTAssertEqual(task.state, NSURLSessionTaskStateSuspended);
    XCTAssertTrue([task isKindOfClass:NSURLSessionDataTask.class]);
    XCTAssertEqualObjects(task.originalRequest, request);
}

- (void)testThatItCreatesADownloadTaskForBackgroundSession;
{
    [self performIgnoringZMLogError:^{
        // given
        [self setupBackgroundSession];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://baz.example.com/1/"]];
        
        // when
        NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:nil transportRequest:nil];
        
        // then
        XCTAssertNotNil(task);
        XCTAssertEqual(task.state, NSURLSessionTaskStateSuspended);
        XCTAssertTrue([task isKindOfClass:NSURLSessionDownloadTask.class]);
        XCTAssertEqualObjects(task.originalRequest, request);
    }];
}

- (void)testThatItCreatesAnUploadTask;
{
    // given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://baz.example.com/1/"]];
    NSData *bodyData = [NSData dataWithBytes:(uint8_t[]){1, 2, 3} length:3];
    
    // when
    NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:bodyData transportRequest:nil];
    
    // then
    XCTAssertNotNil(task);
    XCTAssertEqual(task.state, NSURLSessionTaskStateSuspended);
    XCTAssertTrue([task isKindOfClass:NSURLSessionUploadTask.class]);
    XCTAssertEqualObjects(task.originalRequest, request);
}

- (void)testThatItCreatesATemporaryFileForABackgroundRequest
{
    // given
    [self setupMockBackgroundSession];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://baz.example.com/1/"]];
    NSData *bodyData = [NSData dataWithBytes:(uint8_t[]){1, 2, 3} length:3];
    
    self.sut.temporaryFiles = [OCMockObject mockForClass:ZMTemporaryFileListForBackgroundRequests.class];
    
    // expect
    NSURL *fileURL = [NSURL fileURLWithPath:@"foo"];
    [[[(id)self.sut.temporaryFiles expect] andReturn:fileURL] temporaryFileWithBodyData:bodyData];
    [[[(id)self.sut.temporaryFiles expect] ignoringNonObjectArgs] setTemporaryFile:fileURL forTaskIdentifier:1];
    
    // when
    [self.sut taskWithRequest:request bodyData:bodyData transportRequest:nil];
    
    // then
    [(id)self.sut.temporaryFiles verify];
}

- (void)testThatItDeletesATemporaryFileForABackgroundRequest
{
    // given
    [self setupMockBackgroundSession];
    
    NSUInteger taskID = 4u;
    NSURL *fileURL = [NSURL fileURLWithPath:@"foo"];
    NSURLSessionTask *mockTask = [OCMockObject niceMockForClass:FakeDataTask.class];
    [[[(id)mockTask stub] andReturnValue:OCMOCK_VALUE(taskID)] taskIdentifier];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://baz.example.com/1/"]];
    NSData *bodyData = [NSData dataWithBytes:(uint8_t[]){1, 2, 3} length:3];

    self.sut.temporaryFiles = [OCMockObject mockForClass:ZMTemporaryFileListForBackgroundRequests.class];
    [[[(id)self.sut.backingSession expect] andReturn:mockTask] uploadTaskWithRequest:OCMOCK_ANY fromFile:fileURL];
    
    // expect
    [[[(id)self.sut.temporaryFiles expect] andReturn:fileURL] temporaryFileWithBodyData:bodyData];
    [[[(id)self.sut.temporaryFiles expect] ignoringNonObjectArgs] setTemporaryFile:fileURL forTaskIdentifier:1];
    
    // when
    NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:bodyData transportRequest:nil];
    
    // expect
    [[(id)self.sut.temporaryFiles expect] deleteFileForTaskID:task.taskIdentifier];
    
    // when
    [self.sut URLSession:self.sut.backingSession task:task didCompleteWithError:nil];
    
    // then
    [(id)self.sut.temporaryFiles verify];
}

@end
