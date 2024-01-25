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


#import "ZMClientRegistrationStatus.h"
#import "ZMOperationLoop.h"
#import "ZMAuthenticationStatus_Internal.h"
#import "ZMClientRegistrationStatus+Internal.h"
#import "ZMCredentials.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

@import UIKit;

NSString *const ZMPersistedClientIdKey = @"PersistedClientId";

static NSString *ZMLogTag ZM_UNUSED = @"Authentication";

@interface ZMClientRegistrationStatus ()

@property (nonatomic) BOOL isWaitingForCredentials;

@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;

@property (nonatomic) id clientUpdateToken;
@property (nonatomic) BOOL tornDown;

@end



@implementation ZMClientRegistrationStatus

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                               cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
{
    self = [super init];
    if (self != nil) {
        self.managedObjectContext = moc;
        self.cookieStorage = cookieStorage;
        
        [self observeClientUpdates];
    }
    return self;
}

- (void)determineInitialRegistrationStatus
{
    self.needsToVerifySelfClient = !self.needsToRegisterClient;
    self.needsToFetchFeatureConfigs = self.needsToRegisterClient;
}

- (void)observeClientUpdates
{
    ZM_WEAK(self);
    self.clientUpdateToken = [ZMClientUpdateNotification addObserverWithContext:self.managedObjectContext block:^(enum ZMClientUpdateNotificationType type, NSArray<NSManagedObjectID *> *clientObjectIDs, NSError *error) {
        ZM_STRONG(self);
        [self.managedObjectContext performGroupedBlock:^{
            if (type == ZMClientUpdateNotificationTypeFetchCompleted) {
                [self didFetchClients:clientObjectIDs];
            }
            if (type == ZMClientUpdateNotificationTypeDeletionCompleted) {
                [self didDeleteClient];
            }
            if (type == ZMClientUpdateNotificationTypeDeletionFailed) {
                [self failedDeletingClient:error];
            }
            if (type == ZMClientUpdateNotificationTypeFetchFailed) {
                [self failedFetchingClients:error];
            }
        }];
    }];
}

- (void)tearDown
{
    self.clientUpdateToken = nil;
    self.tornDown = YES;
}

- (void)dealloc
{
    NSAssert(self.tornDown, @"needs to call teardown before deallocating");
}

- (ZMClientRegistrationPhase)currentPhase
{
    /*
     The flow is as follows
     ZMClientRegistrationPhaseWaitingForLogin
     [We try to login / register with the given credentials]
                |
     ZMClientRegistrationPhaseWaitingForSelfUser
     [We fetch the selfUser]
                |
     [User has email address,
      and it's not the SSO user]    --> NO  --> ZMClientRegistrationPhaseWaitingForEmailVerfication
                                                [user adds email and password, we fetch user from BE]
                                            --> ZMClientRegistrationPhaseUnregistered
                                                [Client is registered]
                                            --> ZMClientRegistrationPhaseRegistered
                                    --> YES --> Proceed
     ZMClientRegistrationPhaseUnregistered
     [We try to register the client without the password]
                |
     [Request succeeds ?]           --> YES --> ZMClientRegistrationPhaseRegistered // this is the case for the first device registered
                |
                NO
                |
     [User has email address?]      --> YES --> ZMClientRegistrationPhaseWaitingForLogin 
                                                [User enters password]
                                            --> ZMClientRegistrationPhaseUnregistered
                                                [User entered correct password ?] -->  YES --> Continue at [User has too many devices]
                                                                                  -->  NO  --> ZMClientRegistrationPhaseWaitingForLogin

     [User has too many deviced?]    --> YES --> ZMClientRegistrationPhaseFetchingClients
                                                [User selects device to delete]
                                            --> ZMClientRegistrationPhaseWaitingForDeletion
                                                [BE deletes device]
                                            --> See [NO]
                                     --> NO --> ZMClientRegistrationPhaseUnregistered
                                                [Client is registered]
                                            --> ZMClientRegistrationPhaseRegistered

     [MLS client is required]        --> YES --> ZMClientRegistrationRegisteringMLSClient
                                                 [MLS Client is registered]
                                             --> See [NO]
                                                 [Client is registered]
                                     --> NO  --> ZMClientRegistrationPhaseRegistered

    */
    
    // we only enter this state when the authentication has succeeded
    if (self.isWaitingForLogin) {
        return ZMClientRegistrationPhaseWaitingForLogin;
    }
    
    // before registering client we need to fetch self user to know whether or not the user has registered an email address
    if (self.isWaitingForSelfUser) {
        return ZMClientRegistrationPhaseWaitingForSelfUser;
    }
    
    // when the registration fails because the password is missing or wrong, we need to stop making requests until we have a new password
    if (self.needsToCheckCredentials && self.emailCredentials == nil) {
        return ZMClientRegistrationPhaseWaitingForLogin;
    }

    if (self.needsToFetchFeatureConfigs) {
        return ZMClientRegistrationPhaseWaitingForFetchConfigs;
    }

    if (self.isWaitingForE2EIEnrollment) {
        return ZMClientRegistrationPhaseWaitingForE2EIEnrollment;
    }

    // when the client registration fails because there are too many clients already registered we need to fetch clients from the backend
    if (self.isWaitingForUserClients) {
        return ZMClientRegistrationPhaseFetchingClients;
    }

    // when MLS is enabled we need to register the MLS client to complete client registration
    if (self.isWaitingForMLSClientToBeRegistered) {
        return ZMClientRegistrationPhaseRegisteringMLSClient;
    }

    // when the user
    if (!self.needsToRegisterClient) {
        return ZMClientRegistrationPhaseRegistered;
    }
    
    // when the user has previously only registered by phone and now wants to register a second device, he needs to register his email address and password first
    if (self.isAddingEmailNecessary) {
        return ZMClientRegistrationPhaseWaitingForEmailVerfication;
    }
    
    // when the user has too many clients registered already and selected one device to delete
    if (self.isWaitingForClientsToBeDeleted) {
        return ZMClientRegistrationPhaseWaitingForDeletion;
    }

    if (self.isGeneratingPrekeys) {
        return ZMClientRegistrationPhaseGeneratingPrekeys;
    }

    if (self.prekeys == NULL || self.lastResortPrekey == NULL) {
        return ZMClientRegistrationPhaseWaitingForPrekeys;
    }

    return ZMClientRegistrationPhaseUnregistered;
}

- (BOOL)isWaitingForLogin
{
    return self.cookieStorage.authenticationCookieData == nil;
}

- (BOOL)needsToRegisterClient
{
    return [[self class] needsToRegisterClientInContext:self.managedObjectContext];
}

- (BOOL)needsToRegisterMLSCLient
{
    return [[self class] needsToRegisterMLSClientInContext:self.managedObjectContext];
}

+ (BOOL)needsToRegisterClientInContext:(NSManagedObjectContext *)moc;
{
    //replace with selfUser.client.remoteIdentifier == nil
    NSString *clientId = [moc persistentStoreMetadataForKey:ZMPersistedClientIdKey];
    return ![clientId isKindOfClass:[NSString class]] || clientId.length == 0;
}

- (BOOL)isWaitingForSelfUser
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    return (selfUser.remoteIdentifier == nil);
}

- (BOOL)isWaitingForSelfUserEmail
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    return (selfUser.emailAddress == nil);
}

- (BOOL)isAddingEmailNecessary
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    return ![self.managedObjectContext registeredOnThisDevice] &&
            self.isWaitingForSelfUserEmail &&
           !selfUser.usesCompanyLogin;
}

- (void)didRegisterProteusClient:(UserClient *)client
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    [self.managedObjectContext setPersistentStoreMetadata:client.remoteIdentifier forKey:ZMPersistedClientIdKey];
    [self.managedObjectContext saveOrRollback];
    
    [self fetchExistingSelfClientsAfterClientRegistered:client];

    self.emailCredentials = nil;
    self.needsToCheckCredentials = NO;
    self.prekeys = nil;
    self.lastResortPrekey = nil;

    if (self.needsToRegisterMLSCLient) {
        if (self.needsToEnrollE2EI) {
            self.isWaitingForE2EIEnrollment = YES;
            [self notifyE2EIEnrollmentNecessary];
        } else{
            self.isWaitingForMLSClientToBeRegistered = YES;
        }
    } else {
        [self.registrationStatusDelegate didRegisterSelfUserClient:client];
    }

    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didRegisterMLSClient:(UserClient *)client
{
    self.isWaitingForMLSClientToBeRegistered = NO;
    [self.registrationStatusDelegate didRegisterSelfUserClient:client];
}

- (void)fetchExistingSelfClientsAfterClientRegistered:(UserClient *)currentSelfClient
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];

    NSSet *allClientsExceptCurrent = [selfUser.clients filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier != %@", currentSelfClient.remoteIdentifier]];
    if (allClientsExceptCurrent.count > 0) {
        [currentSelfClient missesClients:allClientsExceptCurrent];
        [currentSelfClient setLocallyModifiedKeys:[NSSet setWithObject:@"missingClients"]];
    }
}

- (void)didFetchClients:(NSArray<NSManagedObjectID *> *)clientIDs;
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
 
    if (self.needsToVerifySelfClient) {
        self.emailCredentials = nil;
        self.needsToVerifySelfClient = NO;
    }
    
    if (self.isWaitingForUserClients) {
        NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
        errorUserInfo[ZMClientsKey] = clientIDs;
        NSError *outError = [NSError userSessionErrorWithErrorCode:ZMUserSessionCanNotRegisterMoreClients userInfo:errorUserInfo];
        [self.registrationStatusDelegate didFailToRegisterSelfUserClient:outError];
        self.isWaitingForUserClients = NO;
        self.isWaitingForClientsToBeDeleted = YES;
    }
}

- (void)failedFetchingClients:(NSError *)error
{
    if (error.code == ClientUpdateErrorSelfClientIsInvalid) {

        ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
        UserClient *selfClient = selfUser.selfClient;

        if (selfClient != nil) {
            // the selfClient was removed by an other user
            [self didDetectCurrentClientDeletion];
        }
        self.needsToVerifySelfClient = NO;
    }
    if (error.code == ClientUpdateErrorDeviceIsOffline) {
        // we do nothing
    }
}

- (void)didDetectCurrentClientDeletion
{
    [self invalidateSelfClient];
    [self.managedObjectContext tearDownCryptoStack];
    [self invalidateCookieAndNotify];
}

- (BOOL)clientIsReadyForRequests
{
    return self.currentPhase == ZMClientRegistrationPhaseRegistered && !self.needsToRegisterMLSCLient;
}

- (void)invalidateSelfClient
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    UserClient *selfClient = selfUser.selfClient;

    selfClient.remoteIdentifier = nil;
    [selfClient resetLocallyModifiedKeys:selfClient.keysThatHaveLocalModifications];
    [self.managedObjectContext setPersistentStoreMetadata:nil forKey:ZMPersistedClientIdKey];
    [self.managedObjectContext saveOrRollback];
}

- (void)failedDeletingClient:(NSError *)error
{
    NOT_USED(error);
    // this should not happen since we just added a password or registered -> hmm
}

@end
