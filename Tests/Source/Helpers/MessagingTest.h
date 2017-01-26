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


@import ZMTesting;
@import WireMessageStrategy;
@import ZMCDataModel;
@import Cryptobox;
@import zimages;

#import "NSManagedObjectContext+TestHelpers.h"


@class NSManagedObjectContext;
@class ZMUser;
@class ZMAssetClientMessage;
@class UserClient;
@class ZMClientMessage;
@class MockTransportSession;

NS_ASSUME_NONNULL_BEGIN



/// This is a base test class with utility stuff for all tests.
@interface MessagingTest : ZMTBaseTest

@property (nonatomic, readonly) NSManagedObjectContext *uiMOC;
@property (nonatomic, readonly) NSManagedObjectContext *syncMOC;
@property (nonatomic, readonly) MockTransportSession *mockTransportSession;
@property (nonatomic, readonly) NSURL *storeURL;
@property (nonatomic, readonly) NSURL *keyStoreURL;


/// perform operations pretending that the uiMOC is a syncMOC
- (void)performPretendingUiMocIsSyncMoc:(void(^)(void))block;

@end




@interface MessagingTest (OTR)

- (UserClient *)createSelfClient;
- (UserClient *)createClientForUser:(ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser;

- (ZMClientMessage *)createClientTextMessage:(BOOL)encrypted;
- (ZMClientMessage *)createClientTextMessage:(NSString *)text encrypted:(BOOL)encrypted;
- (ZMAssetClientMessage *)createImageMessageWithImageData:(NSData *)imageData
                                                   format:(ZMImageFormat)format
                                                processed:(BOOL)processed
                                                   stored:(BOOL)stored
                                                encrypted:(BOOL)encrypted
                                                      moc:(NSManagedObjectContext *)moc;

- (ZMAssetClientMessage *)createImageMessageWithImageData:(NSData *)imageData
                                                   format:(ZMImageFormat)format
                                                processed:(BOOL)processed
                                                   stored:(BOOL)stored
                                                encrypted:(BOOL)encrypted
                                                ephemeral:(BOOL)ephemeral
                                                      moc:(NSManagedObjectContext *)moc;

@end



NS_ASSUME_NONNULL_END
