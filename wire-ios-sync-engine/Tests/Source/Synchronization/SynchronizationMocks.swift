//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import avs
import Foundation
import WireDataModel
@testable import WireSyncEngine

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

    public var deletionCalls: Int = 0

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

@objcMembers
class ZMMockClientRegistrationStatus: ZMClientRegistrationStatus {
    var mockPhase: ClientRegistrationPhase?
    var mockReadiness: Bool = true

    convenience init(managedObjectContext: NSManagedObjectContext) {
        self.init(
            context: managedObjectContext,
            cookieProvider: nil,
            coreCryptoProvider: nil,
            localDomain: "wire.com",
            isBackendMLSEnabled: false
        )
    }

    override init(
        context moc: NSManagedObjectContext!,
        cookieProvider: CookieProvider!,
        coreCryptoProvider: CoreCryptoProviderProtocol!,
        localDomain: String?,
        isBackendMLSEnabled: Bool
    ) {
        super.init(
            context: moc,
            cookieProvider: cookieProvider,
            coreCryptoProvider: coreCryptoProvider,
            localDomain: localDomain,
            isBackendMLSEnabled: isBackendMLSEnabled
        )
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

    var isWaitingForLoginValue: Bool = false
    override var isWaitingForLogin: Bool {
        isWaitingForLoginValue
    }

    var isAddingEmailNecessaryValue: Bool = false
    override var isAddingEmailNecessary: Bool {
        isAddingEmailNecessaryValue
    }

    var didRegisterMLSClient: Bool = false
    override func didRegisterMLSClient(_ client: UserClient) {
        didRegisterMLSClient = true
    }
}

class ZMMockClientUpdateStatus: ClientUpdateStatus {
    var fetchedClients: [UserClient?] = []
    var mockPhase: ClientUpdatePhase?
    var deleteCallCount: Int = 0
    var fetchCallCount: Int = 0
    var mockCredentials: UserEmailCredentials = .init(email: "bla@example.com", password: "secret")

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

class FakeCookieStorage: ZMPersistentCookieStorage {}


@objc
public class MockPushMessageHandler: NSObject, PushMessageHandler {

    public func didFailToSend(_ message: ZMMessage) {
        failedToSend.append(message)
    }

    fileprivate(set) var failedToSend: [ZMMessage] = []
}

@objcMembers
public class MockContextChangeTracker: NSObject, ZMContextChangeTracker {

    public var objectsDidChangeCalled: Bool = false
    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        objectsDidChangeCalled = true
    }

    public var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
    public var fetchRequestForTrackedObjectsCalled: Bool = false
    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        fetchRequestForTrackedObjectsCalled = true
        return fetchRequest
    }

    public var addTrackedObjectsCalled = false
    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        addTrackedObjectsCalled = true
    }

}

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
