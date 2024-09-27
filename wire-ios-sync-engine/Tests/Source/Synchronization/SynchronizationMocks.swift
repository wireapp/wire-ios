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

import AddressBook
import avs
import Foundation
import WireCryptobox
import WireDataModel
@testable import WireSyncEngine

// MARK: - MockApplicationStatus

@objcMembers
public class MockApplicationStatus: NSObject, ApplicationStatus, ClientRegistrationDelegate, ZMRequestCancellation {
    public var taskCancellationDelegate: ZMRequestCancellation { self }
    public var clientRegistrationDelegate: ClientRegistrationDelegate { self }

    public var mockSynchronizationState = SynchronizationState.unauthenticated
    public var synchronizationState: SynchronizationState {
        mockSynchronizationState
    }

    public var mockOperationState = OperationState.foreground
    public var operationState: OperationState {
        mockOperationState
    }

    public var requestCancellation: ZMRequestCancellation {
        self
    }

    // MARK: ZMRequestCancellation

    public var cancelledIdentifiers = [ZMTaskIdentifier]()

    public func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }

    // MARK: ClientRegistrationDelegate

    public var deletionCalls = 0

    /// Notify that the current client was deleted remotely
    public func didDetectCurrentClientDeletion() {
        deletionCalls += 1
    }

    /// Returns true if the client is registered
    public var clientIsReadyForRequests: Bool {
        true
    }

    public var didRequestResyncResources = false
    public func requestResyncResources() {
        didRequestResyncResources = true
    }
}

// MARK: - MockAuthenticationStatus

class MockAuthenticationStatus: ZMAuthenticationStatus {
    var mockPhase: ZMAuthenticationPhase

    init(
        delegate: ZMAuthenticationStatusDelegate,
        phase: ZMAuthenticationPhase = .authenticated,
        userInfoParser: UserInfoParser
    ) {
        self.mockPhase = phase
        super.init(
            delegate: delegate,
            groupQueue: DispatchGroupQueue(queue: .main),
            userInfoParser: userInfoParser
        )
    }

    override var currentPhase: ZMAuthenticationPhase {
        mockPhase
    }
}

// MARK: - ZMMockClientRegistrationStatus

@objcMembers
class ZMMockClientRegistrationStatus: ZMClientRegistrationStatus {
    var mockPhase: ClientRegistrationPhase?
    var mockReadiness = true

    convenience init(managedObjectContext: NSManagedObjectContext) {
        self.init(context: managedObjectContext, cookieProvider: nil, coreCryptoProvider: nil)
    }

    override init(
        context moc: NSManagedObjectContext!,
        cookieProvider: CookieProvider!,
        coreCryptoProvider: CoreCryptoProviderProtocol!
    ) {
        super.init(context: moc, cookieProvider: cookieProvider, coreCryptoProvider: coreCryptoProvider)
        self.emailCredentials = UserEmailCredentials(email: "bla@example.com", password: "secret")
    }

    override var currentPhase: ClientRegistrationPhase {
        if let phase = mockPhase {
            return phase
        }
        return super.currentPhase
    }

    var isLoggedIn: Bool {
        true
    }

    override var clientIsReadyForRequests: Bool {
        mockReadiness
    }

    var isWaitingForLoginValue = false
    override var isWaitingForLogin: Bool {
        isWaitingForLoginValue
    }

    var isAddingEmailNecessaryValue = false
    override var isAddingEmailNecessary: Bool {
        isAddingEmailNecessaryValue
    }
}

// MARK: - ZMMockClientUpdateStatus

class ZMMockClientUpdateStatus: ClientUpdateStatus {
    var fetchedClients: [UserClient?] = []
    var mockPhase: ClientUpdatePhase?
    var deleteCallCount = 0
    var fetchCallCount = 0
    var mockCredentials = UserEmailCredentials(email: "bla@example.com", password: "secret")

    override var credentials: UserEmailCredentials? {
        mockCredentials
    }

    override func didFetchClients(_ clients: [UserClient]) {
        fetchedClients = clients
        fetchCallCount += 1
    }

    override func didDeleteClient() {
        deleteCallCount += 1
    }

    override var currentPhase: ClientUpdatePhase {
        if let mockPhase {
            return mockPhase
        }
        return super.currentPhase
    }
}

// MARK: - FakeCredentialProvider

class FakeCredentialProvider: NSObject, ZMCredentialProvider {
    var clearCallCount = 0
    var email = "hello@example.com"
    var password = "verySafePassword"

    func emailCredentials() -> UserEmailCredentials {
        UserEmailCredentials(email: email, password: password)
    }

    func credentialsMayBeCleared() {
        clearCallCount += 1
    }
}

// MARK: - FakeCookieStorage

class FakeCookieStorage: ZMPersistentCookieStorage {}

// MARK: - MockSyncStatus

public class MockSyncStatus: SyncStatus {
    var didCallFailCurrentSyncPhase = false
    var didCallFinishCurrentSyncPhase = false

    public var mockPhase: SyncPhase = .done {
        didSet {
            currentSyncPhase = mockPhase
        }
    }

    override public func failCurrentSyncPhase(phase: SyncPhase) {
        didCallFailCurrentSyncPhase = true

        super.failCurrentSyncPhase(phase: phase)
    }

    override public func finishCurrentSyncPhase(phase: SyncPhase) {
        didCallFinishCurrentSyncPhase = true

        super.finishCurrentSyncPhase(phase: phase)
    }
}

// MARK: - MockSyncStateDelegate

@objc
public class MockSyncStateDelegate: NSObject, ZMSyncStateDelegate {
    var registeredUserClient: UserClient?
    var registeredMLSClient: UserClient?
    @objc public var didCallStartSlowSync = false
    @objc public var didCallFinishSlowSync = false
    @objc public var didCallStartQuickSync = false
    @objc public var didCallFinishQuickSync = false
    @objc public var didCallFailRegisterUserClient = false
    @objc public var didCallDeleteUserClient = false

    public func didStartSlowSync() {
        didCallStartSlowSync = true
    }

    public func didFinishSlowSync() {
        didCallFinishSlowSync = true
    }

    public func didStartQuickSync() {
        didCallStartQuickSync = true
    }

    public func didFinishQuickSync() {
        didCallFinishQuickSync = true
    }

    public func didRegisterMLSClient(_ userClient: UserClient) {
        registeredMLSClient = userClient
    }

    public func didRegisterSelfUserClient(_ userClient: UserClient) {
        registeredUserClient = userClient
    }

    public func didFailToRegisterSelfUserClient(error: Error) {
        didCallFailRegisterUserClient = true
    }

    public func didDeleteSelfUserClient(error: Error) {
        didCallDeleteUserClient = true
    }
}

// MARK: - MockPushMessageHandler

@objc
public class MockPushMessageHandler: NSObject, PushMessageHandler {
    public func didFailToSend(_ message: ZMMessage) {
        failedToSend.append(message)
    }

    fileprivate(set) var failedToSend: [ZMMessage] = []
}

// MARK: - MockEventConsumer

@objcMembers
public class MockEventConsumer: NSObject, ZMEventConsumer {
    public var eventsProcessed: [ZMUpdateEvent] = []
    public var processEventsCalled = false
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        processEventsCalled = true
        eventsProcessed.append(contentsOf: events)
    }

    public var eventsProcessedWhileInBackground: [ZMUpdateEvent] = []
    public var processEventsWhileInBackgroundCalled = false
    public func processEventsWhileInBackground(_ events: [ZMUpdateEvent]) {
        processEventsWhileInBackgroundCalled = true
        eventsProcessedWhileInBackground.append(contentsOf: events)
    }

    public var messageNoncesToPrefetchCalled = false
    public func messageNoncesToPrefetch(toProcessEvents events: [ZMUpdateEvent]) -> Set<UUID> {
        messageNoncesToPrefetchCalled = true

        return Set(events.compactMap(\.messageNonce))
    }

    public var conversationRemoteIdentifiersToPrefetchCalled = false
    public func conversationRemoteIdentifiersToPrefetch(toProcessEvents events: [ZMUpdateEvent]) -> Set<UUID> {
        conversationRemoteIdentifiersToPrefetchCalled = true

        return Set(events.compactMap(\.conversationUUID))
    }
}

// MARK: - MockContextChangeTracker

@objcMembers
public class MockContextChangeTracker: NSObject, ZMContextChangeTracker {
    public var objectsDidChangeCalled = false
    public func objectsDidChange(_: Set<NSManagedObject>) {
        objectsDidChangeCalled = true
    }

    public var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
    public var fetchRequestForTrackedObjectsCalled = false
    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        fetchRequestForTrackedObjectsCalled = true
        return fetchRequest
    }

    public var addTrackedObjectsCalled = false
    public func addTrackedObjects(_: Set<NSManagedObject>) {
        addTrackedObjectsCalled = true
    }
}

// MARK: - MockEventAsyncConsumer

@objcMembers
public class MockEventAsyncConsumer: NSObject, ZMEventAsyncConsumer {
    public var eventsProcessed: [ZMUpdateEvent] = []
    public var processEventsCalled = false
    public func processEvents(_ events: [WireTransport.ZMUpdateEvent]) async {
        processEventsCalled = true
        eventsProcessed.append(contentsOf: events)
    }
}

// MARK: - MockRequestStrategy

@objcMembers
public class MockRequestStrategy: NSObject, RequestStrategy {
    public var mockRequestQueue: [ZMTransportRequest] = []
    public var mockRequest: ZMTransportRequest? {
        get {
            mockRequestQueue.last
        }
        set {
            if let request = newValue {
                mockRequestQueue = [request]
            } else {
                mockRequestQueue = []
            }
        }
    }

    public var nextRequestCalled = false
    public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        nextRequestCalled = true
        return mockRequestQueue.popLast()
    }
}
