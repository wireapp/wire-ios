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


@import ZMCSystem;
@import ZMUtilities;

#import "ZMAccessTokenHandler.h"
#import "ZMAccessToken.h"
#import "TransportTracing.h"
#import "ZMTransportResponse.h"
#import "ZMTransportData.h"
#import "ZMTransportCodec.h"
#import <mach-o/dyld.h>
#import "ZMPersistentCookieStorage.h"
#import "NSError+ZMTransportSession.h"
#import "ZMUserAgent.h"
#import "ZMTransportRequest.h"
#import "ZMURLSession.h"
#import "ZMTransportRequestScheduler.h"
#import "ZMExponentialBackoff.h"
#import "ZMTLogging.h"


static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK;


static NSTimeInterval const MininumSecondsAccessTokenNeedsToBeValid = 15;

// When we're getting close to the expiry time of the access token, we'll
// renew it.
static NSTimeInterval const GraceperiodToRenewAccessToken = 40;


@interface ZMAccessTokenHandler ()

@property (nonatomic) ZMAccessToken *accessToken;
@property (nonatomic, copy) ZMCompletionHandlerBlock accessTokenRenewalFailureHandler;
@property (nonatomic, copy) ZMAccessTokenHandlerBlock accessTokenRenewalSuccessHandler;
@property (nonatomic) NSURLSessionTask *currentAccessTokenTask;


@property (nonatomic) NSURL *baseURL;
@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic) id<ZMAccessTokenHandlerDelegate> delegate;

@property (nonatomic) ZMExponentialBackoff *backoff;
@property (nonatomic) NSOperationQueue *workQueue;
@property (nonatomic) ZMSDispatchGroup *group;

@property (nonatomic) ZMAccessToken *lastKnownAccessToken;
@end


@implementation ZMAccessTokenHandler

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                  cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                       delegate:(id<ZMAccessTokenHandlerDelegate>)delegate
                          queue:(NSOperationQueue *)queue
                          group:(ZMSDispatchGroup *)group
                        backoff:(ZMExponentialBackoff *)backoff
             initialAccessToken:(ZMAccessToken *)initialAccessToken
{
    self = [super init];
    if (self) {
        self.baseURL = baseURL;
        self.cookieStorage = cookieStorage;
        self.delegate = delegate;
        self.group = group;
        self.workQueue = queue;
        self.backoff = backoff ?: [[ZMExponentialBackoff alloc] initWithGroup:self.group workQueue:self.workQueue];
        self.accessToken = initialAccessToken;
        self.lastKnownAccessToken = initialAccessToken;
    }
    return self;
}

- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler
{
    self->_accessTokenRenewalFailureHandler = [handler copy];
}

- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler
{
    self->_accessTokenRenewalSuccessHandler = [handler copy];
}

- (void)notifyTokenFailure:(ZMTransportResponse *)response;
{
    if (self.accessTokenRenewalFailureHandler) {
        self.accessTokenRenewalFailureHandler(response);
    }
}

- (void)notifyTokenSuccess:(ZMAccessToken *)token
{
    if (self.accessTokenRenewalSuccessHandler) {
        self.accessTokenRenewalSuccessHandler(token.token, token.type);
    }
}

- (void)setAccessToken:(ZMAccessToken *)accessToken
{
    [self willChangeValueForKey:@"accessToken"];
    _accessToken = accessToken;
    [self didChangeValueForKey:@"accessToken"];
    
    if (_accessToken != nil) {
        self.lastKnownAccessToken = accessToken;
        [self.delegate handlerDidReceiveAccessToken:self];
    }
}

- (void)setRequestHeaderFieldsWithLastKnownAccessToken:(NSMutableURLRequest *)request
{
    NSString *token = self.lastKnownAccessToken.token;
    NSString *type = self.lastKnownAccessToken.type;
    if (token == nil || type == nil) {
        return;
    }
    [request setValue:[NSString stringWithFormat:@"%@ %@", type, token] forHTTPHeaderField:@"Authorization"];
}


- (void)checkIfRequest:(ZMTransportRequest *)request needsToFetchAccessTokenInURLRequest:(NSMutableURLRequest *)URLRequest;
{
    if (request.needsAuthentication) {
        [self setRequestHeaderFieldsWithLastKnownAccessToken:URLRequest];
    }
}


- (BOOL)canStartRequestWithAccessToken;
{
    if (self.accessToken == nil) {
        return NO;
    }
    // If expiration is imminent, we assume it won't work:
    return (MininumSecondsAccessTokenNeedsToBeValid < [self.accessToken.expirationDate timeIntervalSinceNow]);
}


- (BOOL)accessTokenIsAboutToExpire;
{
    return ([self.accessToken.expirationDate timeIntervalSinceNow] < GraceperiodToRenewAccessToken);
}

- (BOOL)hasAccessToken;
{
    return self.accessToken != nil;
}

- (void)sendAccessTokenRequestWithURLSession:(ZMURLSession *)URLSession
{
    Require(URLSession != nil);
    if (self.currentAccessTokenTask != nil) {
        ZMTraceTransportSessionAccessTokenRequest(100, (int) 0, self.currentAccessTokenTask.taskIdentifier);
        return;
    }
    
    ZMLogInfo(@"Requesting access token from cookie (existing token: %p).", self.accessToken);
    if(self.cookieStorage.authenticationCookieData == nil) {
        ZMLogError(@"No cookie to request access token");
        [self notifyTokenFailure:nil];
        return;
    }

    NSURL *URL = [NSURL URLWithString:@"/access" relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [ZMUserAgent setUserAgentOnRequest:request];
    [request setHTTPMethod:@"POST"];
    [request addValue:[ZMTransportCodec encodedContentType] forHTTPHeaderField:@"Content-Type"];
    [request addValue:[ZMTransportCodec encodedContentType] forHTTPHeaderField:@"Accept"];
    [self.cookieStorage setRequestHeaderFieldsOnRequest:request];
    [self setRequestHeaderFieldsWithLastKnownAccessToken:request];
    self.currentAccessTokenTask = [URLSession taskWithRequest:request bodyData:nil transportRequest:nil];
    ZMLogInfo(@"----> Access token request: %@ %@ \n %@ \n %@", request.HTTPMethod, request.URL, request.allHTTPHeaderFields, request.HTTPBody);
    ZMTraceTransportSessionAccessTokenRequest(0, 0, self.currentAccessTokenTask.taskIdentifier);

    [self.backoff performBlock:^{
        [self.currentAccessTokenTask resume];
    }];
}



- (BOOL)consumeRequestWithTask:(NSURLSessionTask *)task data:(NSData *)data session:(ZMURLSession *)session shouldRetry:(BOOL)shouldRetry;
{
    if (self.currentAccessTokenTask != task) {
        return NO;
    }

    [self didCompleteAccessTokenRequestWithTask:task data:data session:session shouldRetry:shouldRetry];
    return YES;
}


- (void)didCompleteAccessTokenRequestWithTask:(NSURLSessionTask *)task data:(NSData *)data session:(ZMURLSession *)session shouldRetry:(BOOL)shouldRetry
{
    NSUInteger const taskIdentifier = task.taskIdentifier;
    ZMLogInfo(@"<---- Access token task completed: %@ // %@", task, task.error);
    ZMLogInfo(@"<---- Access token URL session: %@", session.description);
    
    NSError *transportError = [NSError transportErrorFromURLTask:task expired:NO];
    ZMTransportResponse *response = [self transportResponseFromURLResponse:task.response data:data error:transportError];
    ZMTraceTransportSessionAccessTokenRequest(1, (int) response.HTTPStatus, task.taskIdentifier);
    ZMTraceTransportSessionAccessTokenRequest(12, (int) transportError.code, task.taskIdentifier);
    BOOL needToResend = [self processAccessTokenResponse:response taskIdentifier:task.taskIdentifier];
    
    // We can only re-send once we've cleared out the current
    self.currentAccessTokenTask = nil;
    if (needToResend) {
        if (shouldRetry){
            ZMTraceTransportSessionAccessTokenRequest(101, (int) response.result, taskIdentifier);
            [self sendAccessTokenRequestWithURLSession:session];
        } else {
            ZMTraceTransportSessionAccessTokenRequest(102, (int) response.result, taskIdentifier);
        }
    } else {
        ZMTraceTransportSessionAccessTokenRequest(103, (int) response.result, taskIdentifier);
    }
    
    [self updateBackoffWithResponse:response];
}

- (void)updateBackoffWithResponse:(ZMTransportResponse *)response;
{
    NSInteger const statusCode = response.HTTPStatus;
    BOOL const isBackOff = ((statusCode == TooManyRequestsStatusCode) ||
                            (statusCode == EnhanceYourCalmStatusCode));
    BOOL const isInternalError = ((statusCode >= 500) &&
                                  (statusCode <= 599));
    if (isBackOff ||
        isInternalError ||
        (response.result == ZMTransportResponseStatusTemporaryError))
    {
        // Server error or too busy -> increase back-off:
        [self.backoff increaseBackoff];
    } else if (response.result == ZMTransportResponseStatusTryAgainLater) {
        // The request was cancelled (switching to background?). Don't change backoff.
    } else {
        // Permanent error or success:
        [self.backoff resetBackoff];
    }
}


- (ZMTransportResponse *)transportResponseFromURLResponse:(NSURLResponse *)URLResponse data:(NSData *)data error:(NSError *)error;
{
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *) URLResponse;
    return [[ZMTransportResponse alloc] initWithHTTPURLResponse:HTTPResponse data:data error:error];
}



- (BOOL)processAccessTokenResponse:(ZMTransportResponse *)response taskIdentifier:(NSUInteger)taskIdentifier;
{
    ZMLogInfo(@"<---- Access token response: %@", response);
    
    BOOL needsToReRun = YES;
    BOOL didFail = NO;
    self.accessToken = nil;
    
    ZMAccessToken *newToken;
    if (response.result == ZMTransportResponseStatusSuccess) {
        NSUInteger expiresIn = 0;
        if (response.payload != nil) {
            NSString *token = response.payload[@"access_token"];
            NSString *type = response.payload[@"token_type"];
            expiresIn = [response.payload[@"expires_in"] unsignedIntegerValue];
            newToken = [[ZMAccessToken alloc] initWithToken:token type:type expiresInSeconds:expiresIn];
        }
        didFail = (newToken == nil);
        needsToReRun = NO;
        
        if ( ! didFail) {
            self.accessToken = newToken;
            ZMLogInfo(@"New access token <%@: %p>", self.accessToken.class, self.accessToken);
            ZMTraceTransportSessionAccessTokenRequest(3, 0, taskIdentifier);
            [self notifyTokenSuccess:newToken];
        }
        ZMTraceTransportSessionAccessTokenRequest(2, (int) expiresIn, taskIdentifier);
        
    } else if (response.result == ZMTransportResponseStatusPermanentError &&
               response.HTTPStatus != EnhanceYourCalmStatusCode &&
               response.HTTPStatus != TooManyRequestsStatusCode)
    {
        didFail = YES;
        ZMTraceTransportSessionAccessTokenRequest(4, 0, taskIdentifier);
        needsToReRun = NO;
    } else if ((response.result != ZMTransportResponseStatusPermanentError) &&
               (response.result != ZMTransportResponseStatusTryAgainLater))
    {
        ZMTraceTransportSessionAccessTokenRequest(5, 0, taskIdentifier);
    }

    
    if (didFail) {
        ZMLogInfo(@"Clearing access token and cookie");
        self.accessToken = nil;
        self.cookieStorage.authenticationCookieData = nil;
        [self notifyTokenFailure:response];
    }
    
    //ZMTraceAuthTokenResponse(response.HTTPStatus, newToken != nil);
    return needsToReRun;
}


@end


@implementation ZMAccessTokenHandler (Testing)

- (ZMAccessToken *)testing_accessToken {
    return self.accessToken;
}

- (void)setTesting_accessToken:(ZMAccessToken *)testing_accessToken {
    self.accessToken = testing_accessToken;
}

@end

