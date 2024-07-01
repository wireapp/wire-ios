//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@import WireTransport;
@import WireRequestStrategy;

#import <WireSyncEngine/WireSyncEngine-Swift.h>

#import "ZMLoginCodeRequestTranscoder.h"
#import "ZMAuthenticationStatus.h"
#import "ZMAuthenticationStatus.h"
#import "NSError+ZMUserSessionInternal.h"

@interface ZMLoginCodeRequestTranscoder() <ZMSingleRequestTranscoder>

@property (nonatomic, strong) ZMAuthenticationStatus *authenticationStatus;
@property (nonatomic) ZMSingleRequestSync *emailVerificationCodeRequestSync;
@property (nonatomic, weak) id<ZMSGroupQueue> groupQueue;

@end

@implementation ZMLoginCodeRequestTranscoder

- (instancetype)initWithGroupQueue:(id<ZMSGroupQueue>)groupQueue authenticationStatus:(ZMAuthenticationStatus *)authenticationStatus
{
    self = [super init];
    if (self != nil) {
        self.groupQueue = groupQueue;
        self.authenticationStatus = authenticationStatus;

        self.emailVerificationCodeRequestSync = [[ZMSingleRequestSync alloc] initWithSingleRequestTranscoder:self groupQueue:groupQueue];
        [self.emailVerificationCodeRequestSync readyForNextRequest];
    }
    return self;
}

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion
{
    if (self.authenticationStatus.currentPhase == ZMAuthenticationPhaseRequestEmailVerificationCodeForLogin) {
        [self.emailVerificationCodeRequestSync readyForNextRequestIfNotBusy];
        return [self.emailVerificationCodeRequestSync nextRequestForAPIVersion:apiVersion];
    }
    return nil;
}

#pragma mark - ZMSingleRequestTranscoder

- (ZMTransportRequest *)requestForSingleRequestSync:(__unused ZMSingleRequestSync *)sync apiVersion:(APIVersion)apiVersion;
{
    if (sync == self.emailVerificationCodeRequestSync) {
        ZMTransportRequest *emailVerficationCodeRequest = [[ZMTransportRequest alloc] initWithPath:@"/verification-code/send"
                                                                                            method:ZMTransportRequestMethodPost
                                                                                           payload:@{@"email": self.authenticationStatus.loginEmailThatNeedsAValidationCode,
                                                                                                     @"action": @"login"
                                                                                                   }
                                                                                    authentication:ZMTransportRequestAuthNone
                                                                                        apiVersion:apiVersion];
        return emailVerficationCodeRequest;
    }

    return nil;
}

- (void)didReceiveResponse:(ZMTransportResponse *)response forSingleRequest:(__unused ZMSingleRequestSync *)sync
{
    ZMAuthenticationStatus *authStatus  = self.authenticationStatus;
    if(response.result == ZMTransportResponseStatusSuccess) {
        [authStatus didCompleteRequestForLoginCodeSuccessfully];
    }
    else {
        NSError *error = {
            [NSError pendingLoginErrorWithResponse:response] ?:
            [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeUnknownError userInfo:nil]
        };

        [authStatus didFailRequestForLoginCode:error];
    }
}

@end
