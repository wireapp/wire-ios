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



#import <Foundation/Foundation.h>
#import <ZMCSystem/ZMCSystem.h>

@class ZMTransportRequest;
@class ZMTimer;
@class ZMURLSession;
@protocol ZMURLSessionDelegate;



@interface ZMURLSession : NSObject

+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id<ZMURLSessionDelegate>)delegate delegateQueue:(NSOperationQueue *)queue;

- (void)setTimeoutTimer:(ZMTimer *)timer forTask:(NSURLSessionTask *)task;

- (void)cancelAndRemoveAllTimers;
- (void)cancelAllTasksWithCompletionHandler:(dispatch_block_t)handler;
- (void)countTasksWithCompletionHandler:(void(^)(NSUInteger count))handler ZM_NON_NULL(1);

- (void)tearDown;

/// The completion handler will be called with YES if the task was cancelled.
- (void)cancelTaskWithIdentifier:(NSUInteger)taskIdentifier completionHandler:(void(^)(BOOL))handler;

@property (nonatomic, readonly) NSURLSessionConfiguration *configuration;

@end




@interface ZMURLSession (TaskGeneration)

@property (nonatomic, readonly) BOOL isBackgroundSession;

- (NSURLSessionTask *)taskWithRequest:(NSURLRequest *)request bodyData:(NSData *)bodyData transportRequest:(ZMTransportRequest *)request;

@end



@protocol ZMURLSessionDelegate

- (void)URLSession:(ZMURLSession *)URLSession
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;

- (void)URLSessionDidReceiveData:(ZMURLSession *)URLSession;

- (void)URLSession:(ZMURLSession *)URLSession
   taskDidComplete:(NSURLSessionTask *)task
  transportRequest:(ZMTransportRequest *)transportRequest
      responseData:(NSData *)responseData;

@end
