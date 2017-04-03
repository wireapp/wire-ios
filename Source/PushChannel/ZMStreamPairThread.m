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


#import "ZMStreamPairThread.h"
@import WireSystem;

@import ObjectiveC;



@interface ZMStreamPairThread ()

@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;

@end


static BOOL canSetQualityOfService()
{
    static BOOL canSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canSet = (NULL != class_getProperty([ZMStreamPairThread class], "numberOfValidItemsForDrop"));
    });
    return canSet;
}


@implementation ZMStreamPairThread

- (instancetype)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
{
    VerifyReturnNil(inputStream != nil);
    VerifyReturnNil(outputStream != nil);
    self = [super init];
    if (self) {
        self.shouldKeepRunning = YES;
        self.inputStream = inputStream;
        self.outputStream = outputStream;
        self.name = @"ZMStreamPairThread";
        if (canSetQualityOfService()) {
            self.qualityOfService = NSQualityOfServiceUtility;
        }
    }
    return self;
}

- (void)main;
{
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    [self.inputStream scheduleInRunLoop:loop forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:loop forMode:NSDefaultRunLoopMode];
    while (self.shouldKeepRunning && [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
    {}
}

@end
