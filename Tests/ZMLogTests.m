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


#import <XCTest/XCTest.h>
#import <ZMCSystem/ZMCSystem.h>
#import "ZMSLogging+Testing.h"

static char* const ZMLogTag = "Testing";
static NSString *const TagForTests = @"Testing";

@interface TestLog : NSObject

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *message;

- (instancetype)initWithTag:(NSString *)tag message:(NSString *)message;

@end



@implementation TestLog

- (instancetype)initWithTag:(NSString *)tag message:(NSString *)message
{
    self = [super init];
    if(self) {
        self.tag = tag;
        self.message = message;
    }
    return self;
}

@end


@interface ZMLogTests : XCTestCase

@property (nonatomic) NSMutableArray *receivedLogs; // array of TestLog

@end

@implementation ZMLogTests

- (void)setUp
{
    [super setUp];
    self.receivedLogs = [NSMutableArray array];
    ZMLogTestingResetLogLevels();
    ZMLoggingDebuggingHook = ^void(const char *tag, char const * const filename __unused, int linenumber __unused, NSString *output){
        [self.receivedLogs addObject:[[TestLog alloc] initWithTag:(tag ? [NSString stringWithUTF8String:tag] : nil) message:output]];
    };
}

- (void)tearDown
{
    [self removeTestLogSnapshotIfNeeded];
    ZMLogTestingResetLogLevels();
    [super tearDown];
}

- (void)removeTestLogSnapshotIfNeeded;
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self filepathForSavingLogs]]) {
        [fm removeItemAtPath:[self filepathForSavingLogs] error:nil];
    }
}

- (NSString *)filepathForSavingLogs;
{
    
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL * const directory = [fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    RequireString(directory != nil, "Failed to get or create directory: %lu", (long) error.code);
    NSString *identifier = [NSBundle bundleForClass:[self class]].bundleIdentifier;
    NSURL *finalLocation = [[directory URLByAppendingPathComponent:identifier] URLByAppendingPathComponent:@"SavedLogs"];
    
    if (![[NSFileManager defaultManager] createDirectoryAtURL:finalLocation withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"error: %@", error);
    }
    NSString *filename = [NSString stringWithFormat:@"%@-test.log", identifier];
    return [finalLocation URLByAppendingPathComponent:filename].path;

}

- (void)testThatTheLogTagIsNotRegisteredIfNoLogIsCalled
{
    NSSet *tags = ZMLogGetAllTags();
    XCTAssertFalse([tags containsObject:TagForTests]);
}

- (void)testThatTheLogTagIsRegisteredAfterLoggingDebug
{
    ZMLogDebug(@"This log should cause the ZMLogTag to be registered");
    NSSet *tags = ZMLogGetAllTags();
    XCTAssertTrue([tags containsObject:TagForTests]);
}

- (void)testThatTheLogTagIsRegisteredAfterLoggingInfo
{
    ZMLogInfo(@"This log should cause the ZMLogTag to be registered");
    NSSet *tags = ZMLogGetAllTags();
    XCTAssertTrue([tags containsObject:TagForTests]);
}

- (void)testThatTheLoggingDebugHookIsNotCalledAfterLoggingInfo
{
    NSString *logMessage = @"This is a test message";
    ZMLogSetLevelForTag(ZMLogLevelInfo, TagForTests.UTF8String);
    ZMLogInfo(@"%@", logMessage);
    
    XCTAssertEqual(self.receivedLogs.count, 0u);
}

- (void)testThatTheLoggingDebugHookIsNotCalledAfterLoggingDebug
{
    NSString *logMessage = @"This is a test message";
    ZMLogDebug(@"%@", logMessage);
    
    XCTAssertEqual(self.receivedLogs.count, 0u);
}

- (void)testThatTheLoggingDebugHookIsCalledAfterLoggingWarning
{
    NSString *logMessage = @"This is a test message";
    ZMLogWarn(@"%@", logMessage);
    
    XCTAssertEqual(self.receivedLogs.count, 1u);
    TestLog *firstLog = self.receivedLogs.firstObject;
    XCTAssertNil(firstLog.tag);
    XCTAssertEqualObjects(firstLog.message, logMessage);
}

- (void)testThatTheLoggingDebugHookIsCalledAfterLoggingError
{
    NSString *logMessage = @"This is a test message";
    ZMLogError(@"%@", logMessage);
    
    XCTAssertEqual(self.receivedLogs.count, 1u);
    TestLog *firstLog = self.receivedLogs.firstObject;
    XCTAssertNil(firstLog.tag);
    XCTAssertEqualObjects(firstLog.message, logMessage);
}

- (void)testThatTheDefaultLogLevelIsWarning
{
    XCTAssertEqual(ZMLogGetLevelForTag("Testing"), ZMLogLevelWarn);
    XCTAssertEqual(ZMLogGetLevelForTag("FooBar"), ZMLogLevelWarn);
}

- (void)testThatTheLogLevelCanBeSet
{
    ZMLogSetLevelForTag(ZMLogLevelInfo, "FooBar");
    XCTAssertEqual(ZMLogGetLevelForTag("FooBar"), ZMLogLevelInfo);
}

- (void)testThatALogTagIsInitialized
{
    ZMLogInitForTag("Alice");
    ZMLogInitForTag("Bob");
    NSSet *expected = [NSSet setWithObjects:@"Bob", @"Alice", nil];
    XCTAssertEqualObjects(expected, ZMLogGetAllTags());
}

- (void)testThatLogMacrosCompile    
{
    ZMLogError(@"Test");
    ZMLogWarn(@"Test");
    ZMLogInfo(@"Test");
    ZMLogDebug(@"Test");
}

- (void)testThatSnapshotsIsFunctioning
{
    ZMLogDebug(@"value of i: %d", 1);
    ZMLogWarn(@"value of i: %d", 2);
    ZMLogError(@"value of i: %d", 3);
    
    NSString *filepath = [self filepathForSavingLogs];
    
    ZMLogSnapshot(filepath);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:filepath]);
    NSString *logs = [NSString stringWithContentsOfFile:filepath encoding:NSASCIIStringEncoding error:nil];
    XCTAssertNotNil(logs);
}

@end
