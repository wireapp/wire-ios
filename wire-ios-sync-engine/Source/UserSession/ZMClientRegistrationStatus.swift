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

import Foundation
import WireDataModel
import WireSystem

@objc(ZMClientRegistrationPhase)
public enum ClientRegistrationPhase: UInt {
    /// The client is not registered - we send out a request to register the client
    case unregistered = 0

    /// the user is not logged in yet or has entered the wrong credentials - we don't send out any requests
    case waitingForLogin

    /// the user is logged in but is waiting to fetch the selfUser - we send out a request to fetch the selfUser
    case waitingForSelfUser

    /// the user is logged in but is waiting to fetch the fetching config
    case waitingForFetchConfigs

    // we are for the user to finish the end-to-end identity enrollment
    case waitingForE2EIEnrollment

    /// the user has too many devices registered - we send a request to fetch all devices
    case fetchingClients

    /// the user has selected a device to delete - we send a request to delete the device
    case waitingForDeletion

    /// the user has registered with phone but needs to register an email address and password to register a second
    /// device - we wait until we have emailCredentials
    case waitingForEmailVerfication

    /// the user has not yet selected a handle, which is a requirement for registering a client.
    case waitingForHandle

    /// waiting for proteus prekeys to be generated
    case waitingForPrekeys

    /// proteus prekeys are being generated
    case generatingPrekeys

    /// waiting for the MLS client to be registered
    case registeringMLSClient

    /// The client is registered
    case registered
}

extension ClientRegistrationPhase: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unregistered:
            "unregistered"
        case .waitingForLogin:
            "waitingForLogin"
        case .waitingForSelfUser:
            "waitingForSelfUser"
        case .waitingForFetchConfigs:
            "waitingForFetchConfigs"
        case .waitingForE2EIEnrollment:
            "waitingForE2EIEnrollment"
        case .fetchingClients:
            "fetchingClients"
        case .waitingForDeletion:
            "waitingForDeletion"
        case .waitingForEmailVerfication:
            "waitingForEmailVerfication"
        case .waitingForHandle:
            "waitingForHandle"
        case .waitingForPrekeys:
            "waitingForPrekeys"
        case .generatingPrekeys:
            "generatingPrekeys"
        case .registeringMLSClient:
            "registeringMLSClient"
        case .registered:
            "registered"
        }
    }
}

@objc
public class ZMClientRegistrationStatus: NSObject, ClientRegistrationDelegate {
    @objc public weak var registrationStatusDelegate: ZMClientRegistrationStatusDelegate?
    @objc public var emailCredentials: UserEmailCredentials?
    var prekeys: [IdPrekeyTuple]?
    var lastResortPrekey: IdPrekeyTuple?

    private let managedObjectContext: NSManagedObjectContext
    private let cookieProvider: CookieProvider
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private var needsRefreshSelfUser = false
    private var needsToCheckCredentials = false
    private var needsToFetchFeatureConfigs = false
    private var needsToVerifySelfClient = false
    private var isWaitingForE2EIEnrollment = false
    private var isWaitingForUserClients = false
    private var isWaitingForMLSClientToBeRegistered = false
    private var isWaitingForClientsToBeDeleted = false
    private var isGeneratingPrekeys = false

    private var userProfileObserverToken: Any?
    private var clientUpdateObserverToken: Any?

    public init(
        context: NSManagedObjectContext,
        cookieProvider: CookieProvider,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.managedObjectContext = context
        self.cookieProvider = cookieProvider
        self.coreCryptoProvider = coreCryptoProvider

        super.init()

        observeClientUpdates()
        observeProfileUpdates()
    }

    @objc public var currentPhase: ClientRegistrationPhase {
        // The flow is as follows
        // ZMClientRegistrationPhaseWaitingForLogin
        // [We try to login / register with the given credentials]
        //            |
        // ZMClientRegistrationPhaseWaitingForSelfUser
        // [We fetch the selfUser]
        //            |
        // [User has email address,
        //  and it's not the SSO user]    --> NO  --> ZMClientRegistrationPhaseWaitingForEmailVerfication
        //                                            [user adds email and password, we fetch user from BE]
        //                                        --> ZMClientRegistrationPhaseUnregistered
        //                                            [Client is registered]
        //                                        --> ZMClientRegistrationPhaseRegistered
        //                                --> YES --> Proceed
        // ZMClientRegistrationPhaseUnregistered
        // [We try to register the client without the password]
        //            |
        // [Request succeeds ?]           --> YES --> ZMClientRegistrationPhaseRegistered // this is the case for the
        // first device registered
        //            |
        //            NO
        //            |
        // [User has email address?]      --> YES --> ZMClientRegistrationPhaseWaitingForLogin
        //                                            [User enters password]
        //                                        --> ZMClientRegistrationPhaseUnregistered
        //                                            [User entered correct password ?] -->  YES --> Continue at [User
        // has too many devices]
        //                                                                              -->  NO  -->
        // ZMClientRegistrationPhaseWaitingForLogin
        //
        // [User has too many deviced?]    --> YES --> ZMClientRegistrationPhaseFetchingClients
        //                                            [User selects device to delete]
        //                                        --> ZMClientRegistrationPhaseWaitingForDeletion
        //                                            [BE deletes device]
        //                                        --> See [NO]
        //                                 --> NO --> ZMClientRegistrationPhaseUnregistered
        //                                            [Client is registered]
        //                                        --> ZMClientRegistrationPhaseRegistered
        //
        // [MLS client is required]        --> YES --> ZMClientRegistrationRegisteringMLSClient
        //                                             [MLS Client is registered]
        //                                         --> See [NO]
        //                                             [Client is registered]
        //                                 --> NO  --> ZMClientRegistrationPhaseRegistered
        //

        // we only enter this state when the authentication has succeeded
        if isWaitingForLogin {
            return .waitingForLogin
        }

        // before registering client we need to fetch self user to know whether or not the user has registered an email
        // address
        if isWaitingForSelfUser || needsRefreshSelfUser {
            return .waitingForSelfUser
        }

        // when the registration fails because the password is missing or wrong, we need to stop making requests until
        // we have a new password
        if needsToCheckCredentials && emailCredentials == nil {
            return .waitingForLogin
        }

        if needsToFetchFeatureConfigs {
            return .waitingForFetchConfigs
        }

        if isWaitingForE2EIEnrollment {
            return .waitingForE2EIEnrollment
        }

        // when the client registration fails because there are too many clients already registered we need to fetch
        // clients from the backend
        if isWaitingForUserClients {
            return .fetchingClients
        }

        // when MLS is enabled we need to register the MLS client to complete client registration
        if isWaitingForMLSClientToBeRegistered {
            return .registeringMLSClient
        }

        // when the user
        if !needsToRegisterClient {
            return .registered
        }

        // a handle is a requirement to complete client registration
        if isAddingHandleNecessary {
            return .waitingForHandle
        }

        // when the user has previously only registered by phone and now wants to register a second device, he needs to
        // register his email address and password first
        if isAddingEmailNecessary {
            return .waitingForEmailVerfication
        }

        // when the user has too many clients registered already and selected one device to delete
        if isWaitingForClientsToBeDeleted {
            return .waitingForDeletion
        }

        if isGeneratingPrekeys {
            return .generatingPrekeys
        }

        if prekeys == nil || lastResortPrekey == nil {
            return .waitingForPrekeys
        }

        return .unregistered
    }

    public var clientIsReadyForRequests: Bool {
        currentPhase == .registered && !needsToRegisterMLSCLient
    }

    var isWaitingForLogin: Bool {
        !cookieProvider.isAuthenticated
    }

    var needsToRegisterClient: Bool {
        Self.needsToRegisterClient(in: managedObjectContext)
    }

    var needsToRegisterMLSCLient: Bool {
        Self.needsToRegisterMLSClient(in: managedObjectContext)
    }

    @objc(needsToRegisterClientInContext:)
    public static func needsToRegisterClient(in context: NSManagedObjectContext) -> Bool {
        // replace with selfUser.client.remoteIdentifier == nil
        if let clientID = context.persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String {
            clientID.isEmpty
        } else {
            true
        }
    }

    var isWaitingForSelfUser: Bool {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        return selfUser.remoteIdentifier == nil
    }

    var isWaitingForSelfUserEmail: Bool {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        return selfUser.emailAddress == nil
    }

    var isAddingEmailNecessary: Bool {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        return !managedObjectContext.registeredOnThisDevice && isWaitingForSelfUserEmail && !selfUser.usesCompanyLogin
    }

    var isAddingHandleNecessary: Bool {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        return selfUser.handle == nil
    }

    func determineInitialRegistrationStatus() {
        needsToVerifySelfClient = !needsToRegisterClient
        needsToFetchFeatureConfigs = needsToRegisterClient
        needsRefreshSelfUser = needsToRegisterClient

        if !needsToRegisterClient, needsToRegisterMLSCLient {
            guard let client = ZMUser.selfUser(in: managedObjectContext).selfClient() else {
                fatal("Expected a self user client to exist")
            }
            createMLSClient(client: client)
        }
    }

    func observeProfileUpdates() {
        userProfileObserverToken = UserProfileUpdateStatus.add(
            observer: self,
            in: managedObjectContext.notificationContext
        )
    }

    func observeClientUpdates() {
        clientUpdateObserverToken = ZMClientUpdateNotification
            .addObserver(context: managedObjectContext) { [weak self] type, clientIDs, error in
                self?.managedObjectContext.performGroupedBlock {
                    switch type {
                    case .fetchCompleted:
                        self?.didFetchClients(clientIDs: clientIDs)
                    case .deletionCompleted:
                        self?.didDeleteClient()
                    case .deletionFailed:
                        self?.failedDeletingClient(error: error)
                    case .fetchFailed:
                        self?.failedFetchingClients(error: error)
                    }
                }
            }
    }

    @objc(didFailToRegisterClient:)
    public func didFail(toRegisterClient error: NSError) {
        WireLogger.authentication.debug(#function)

        var error: NSError = error

        // we should not reset login state for client registration errors
        if error.code != UserSessionErrorCode.needsPasswordToRegisterClient.rawValue && error
            .code != UserSessionErrorCode.needsToRegisterEmailToRegisterClient.rawValue && error
            .code != UserSessionErrorCode.canNotRegisterMoreClients.rawValue {
            emailCredentials = nil
        }

        if error.code == UserSessionErrorCode.needsPasswordToRegisterClient.rawValue {
            // help the user by providing the email associated with this account
            error = NSError(
                domain: error.domain,
                code: error.code,
                userInfo: ZMUser.selfUser(in: managedObjectContext).loginCredentials.dictionaryRepresentation
            )
        }

        if error.code == UserSessionErrorCode.needsPasswordToRegisterClient.rawValue || error
            .code == UserSessionErrorCode.invalidCredentials.rawValue {
            // set this label to block additional requests while we are waiting for the user to (re-)enter the password
            needsToCheckCredentials = true
        }

        if error.code == UserSessionErrorCode.canNotRegisterMoreClients.rawValue {
            // Wait and fetch the clients before sending the error
            isWaitingForUserClients = true
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        } else {
            registrationStatusDelegate?.didFailToRegisterSelfUserClient(error: error)
        }
    }

    @objc
    public func invalidateCookieAndNotify() {
        emailCredentials = nil
        cookieProvider.deleteKeychainItems()

        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        let outError = NSError.userSessionError(
            code: .clientDeletedRemotely,
            userInfo: selfUser.loginCredentials.dictionaryRepresentation
        )
        registrationStatusDelegate?.didDeleteSelfUserClient(error: outError)
    }

    @objc
    public func prepareForClientRegistration() {
        WireLogger.userClient.info("preparing for client registration")

        guard needsToRegisterClient else {
            WireLogger.userClient.info("no need to register client. aborting client registration")
            return
        }

        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        guard selfUser.remoteIdentifier != nil else {
            WireLogger.userClient.info("identifier for self user is nil. aborting client registration")
            return
        }

        if needsToCreateNewClientForSelfUser(selfUser) {
            WireLogger.userClient.info("client creation needed. will insert client in context")
            insertNewClient(for: selfUser)
        } else {
            // there is already an unregistered client in the store
            // since there is no change in the managedObject, it will not trigger [ZMRequestAvailableNotification
            // notifyNewRequestsAvailable:] automatically
            // therefore we need to call it here
            WireLogger.userClient.info("unregistered client found. notifying available requests")
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    private func insertNewClient(for selfUser: ZMUser) {
        UserClient.insertNewSelfClient(
            in: managedObjectContext,
            selfUser: selfUser,
            model: UIDevice.current.zm_model(),
            label: UIDevice.current.name
        )

        managedObjectContext.saveOrRollback()
    }

    private func needsToCreateNewClientForSelfUser(_ selfUser: ZMUser) -> Bool {
        if let selfClient = selfUser.selfClient(), !selfClient.isZombieObject {
            WireLogger.userClient.info("self user has viable self client. no need to create new self client")
            return false
        }

        let hasNotYetRegisteredClient = selfUser.clients.contains(where: { $0.remoteIdentifier == nil })

        if !hasNotYetRegisteredClient {
            WireLogger.userClient
                .info("self user has no client that isn't yet registered. will need to create new self client")
        } else {
            WireLogger.userClient
                .info("self user has a client that isn't yet registered. no need to create new self client")
        }

        return !hasNotYetRegisteredClient
    }

    private func fetchFeatureConfigs() {
        var action = GetFeatureConfigsAction()
        action.perform(in: managedObjectContext.notificationContext) { [weak self] result in
            switch result {
            case .success:
                self?.didFetchFeatureConfigs()
            case .failure:
                self?.fetchFeatureConfigs()
            }
        }
    }

    @objc
    public func didDeleteClient() {
        WireLogger.userClient.info("client was deleted. will prepare for registration")

        if isWaitingForClientsToBeDeleted {
            isWaitingForClientsToBeDeleted = false
            prepareForClientRegistration()
        }
    }

    @objc(didRegisterProteusClient:)
    public func didRegisterProteusClient(_ client: UserClient) {
        WireLogger.authentication.info("Did register proteus client")

        managedObjectContext.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)
        managedObjectContext.saveOrRollback()

        fetchExistingSelfClientsAfterRegisteringClient(client)

        emailCredentials = nil
        needsToCheckCredentials = false
        prekeys = nil
        lastResortPrekey = nil

        if needsToRegisterMLSCLient {
            createMLSClient(client: client)
        } else {
            registrationStatusDelegate?.didRegisterSelfUserClient(client)
        }

        WireLogger.authentication.debug("current phase: \(currentPhase)")
    }

    private func createMLSClient(client: UserClient) {
        if needsToEnrollE2EI {
            isWaitingForE2EIEnrollment = true
            notifyE2EIEnrollmentNecessary()
        } else {
            guard let mlsClientID = MLSClientID(userClient: client) else {
                fatalError("Needs to register MLS client but can't retrieve qualified client ID")
            }

            WaitingGroupTask(context: managedObjectContext) {
                do {
                    try await self.coreCryptoProvider.initialiseMLSWithBasicCredentials(mlsClientID: mlsClientID)
                } catch {
                    WireLogger.mls.error("Failed to initialise mls client: \(error)")
                }
            }
            isWaitingForMLSClientToBeRegistered = true
        }
    }

    private func fetchExistingSelfClientsAfterRegisteringClient(_ selfClient: UserClient) {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        let otherClients = selfUser.clients.filter { client in
            client.remoteIdentifier != selfClient.remoteIdentifier
        }

        if !otherClients.isEmpty {
            selfClient.missesClients(otherClients)
            selfClient.setLocallyModifiedKeys(Set(["missingClients"]))
        }
    }

    func didRegisterMLSClient(_ client: UserClient) {
        isWaitingForMLSClientToBeRegistered = false
        registrationStatusDelegate?.didRegisterSelfUserClient(client)
    }

    func didFetchClients(clientIDs: [NSManagedObjectID]) {
        WireLogger.authentication.debug("didFetchClients(clientIDs:)")

        if needsToVerifySelfClient {
            emailCredentials = nil
            needsToVerifySelfClient = false
        }

        if isWaitingForUserClients {
            self.isWaitingForUserClients = false
            self.isWaitingForClientsToBeDeleted = true
            notifyCanNotRegisterMoreClients(clientIDs: clientIDs)
        }
    }

    func failedFetchingClients(error: NSError?) {
        if error?.domain == ClientUpdateErrorDomain, error?.code == ClientUpdateError.selfClientIsInvalid.rawValue {
            let selfUser = ZMUser.selfUser(in: managedObjectContext)
            let selfClient = selfUser.selfClient()

            if selfClient != nil {
                // the selfClient was removed by an other user
                didDetectCurrentClientDeletion()
            }
            needsToVerifySelfClient = false
        }
    }

    func failedDeletingClient(error: Error?) {
        // this should not happen since we just added a password or registered -> hmm
    }

    public func didDetectCurrentClientDeletion() {
        invalidateSelfClient()
        managedObjectContext.tearDownCryptoStack()
        invalidateCookieAndNotify()
    }

    func invalidateSelfClient() {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        guard let selfClient = selfUser.selfClient() else {
            return
        }

        selfClient.remoteIdentifier = nil
        selfClient.resetLocallyModifiedKeys(selfClient.keysThatHaveLocalModifications)
        selfClient.clearMLSPublicKeys()
        managedObjectContext.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
        managedObjectContext.saveOrRollback()
    }

    @objc
    public func didFetchSelfUser() {
        WireLogger.userClient.info("did fetch self user")
        self.needsRefreshSelfUser = false

        if needsToRegisterClient {
            prepareForClientRegistration()

            if isAddingHandleNecessary {
                notifyHandleIsNecessary()
            } else if isAddingEmailNecessary {
                notifyEmailIsNecessary()
            }
        } else if !needsToVerifySelfClient {
            emailCredentials = nil
        }

        if needsToFetchFeatureConfigs {
            fetchFeatureConfigs()
        }
    }

    @objc
    public func didFetchFeatureConfigs() {
        WireLogger.userClient.info("did fetch feature configs")
        needsToFetchFeatureConfigs = false
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

    private func notifyEmailIsNecessary() {
        let error = NSError(
            domain: NSError.userSessionErrorDomain,
            code: UserSessionErrorCode.needsToRegisterEmailToRegisterClient.rawValue
        )

        registrationStatusDelegate?.didFailToRegisterSelfUserClient(error: error)
    }

    @objc
    public func notifyE2EIEnrollmentNecessary() {
        let error = NSError(
            domain: NSError.userSessionErrorDomain,
            code: UserSessionErrorCode.needsToEnrollE2EIToRegisterClient.rawValue
        )
        registrationStatusDelegate?.didFailToRegisterSelfUserClient(error: error)
    }

    private func notifyHandleIsNecessary() {
        let error = NSError(
            domain: NSError.userSessionErrorDomain,
            code: UserSessionErrorCode.needsToHandleToRegisterClient.rawValue
        )

        registrationStatusDelegate?.didFailToRegisterSelfUserClient(error: error)
    }

    private func notifyCanNotRegisterMoreClients(clientIDs: [NSManagedObjectID]) {
        let error = NSError(
            domain: NSError.userSessionErrorDomain,
            code: UserSessionErrorCode.canNotRegisterMoreClients.rawValue,
            userInfo: [ZMClientsKey: clientIDs]
        )

        registrationStatusDelegate?.didFailToRegisterSelfUserClient(error: error)
    }

    @objc public var needsToEnrollE2EI: Bool {
        FeatureRepository(context: managedObjectContext).fetchE2EI().isEnabled
    }

    @objc(needsToRegisterMLSClientInContext:)
    public static func needsToRegisterMLSClient(in context: NSManagedObjectContext) -> Bool {
        guard !self.needsToRegisterClient(in: context) else {
            return false
        }
        let hasRegisteredMLSClient = ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient ?? false
        let isAllowedToRegisterMLSCLient = DeveloperFlag.enableMLSSupport.isOn && (BackendInfo.apiVersion ?? .v0) >= .v5
        return !hasRegisteredMLSClient && isAllowedToRegisterMLSCLient
    }

    public func willGeneratePrekeys() {
        isGeneratingPrekeys = true
    }

    public func didGeneratePrekeys(_ prekeys: [IdPrekeyTuple], lastResortPrekey: IdPrekeyTuple) {
        self.prekeys = prekeys
        self.lastResortPrekey = lastResortPrekey
        self.isGeneratingPrekeys = false
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

    public func didEnrollIntoEndToEndIdentity() {
        WireLogger.userClient.info("user client did enroll into end-2-end idenity")
        isWaitingForE2EIEnrollment = false
        isWaitingForMLSClientToBeRegistered = true
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }
}

extension ZMClientRegistrationStatus: UserProfileUpdateObserver {
    public func didSetHandle() {
        managedObjectContext.perform { [self] in
            if needsToRegisterClient {
                if isAddingEmailNecessary {
                    notifyEmailIsNecessary()
                }
            }
        }
    }
}
