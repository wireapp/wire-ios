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
import WireRequestStrategy

public class MockApplicationStatus: NSObject, ApplicationStatus {
    public var requestCancellation: ZMRequestCancellation {
        mockTaskCancellationDelegate
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        mockClientRegistrationStatus
    }

    public var mockSynchronizationState: SynchronizationState = .unauthenticated
    public let mockTaskCancellationDelegate = MockTaskCancellationDelegate()
    public var mockClientRegistrationStatus = MockClientRegistrationStatus()

    public var synchronizationState: SynchronizationState {
        mockSynchronizationState
    }

    public var mockOperationState: OperationState = .foreground

    public var operationState: OperationState {
        mockOperationState
    }

    public var cancelledIdentifiers: [ZMTaskIdentifier] {
        mockTaskCancellationDelegate.cancelledIdentifiers
    }

    public var deletionCalls: Int {
        mockClientRegistrationStatus.deletionCalls
    }

    public var resyncResourcesWasRequested = false
    public func requestResyncResources() {
        resyncResourcesWasRequested = true
    }
}

public class MockTaskCancellationDelegate: NSObject, ZMRequestCancellation {
    public var cancelledIdentifiers = [ZMTaskIdentifier]()

    public func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }
}

public class MockClientRegistrationStatus: NSObject, ClientRegistrationDelegate {
    public var deletionCalls = 0

    /// Notify that the current client was deleted remotely
    public func didDetectCurrentClientDeletion() {
        deletionCalls += 1
    }

    public var clientIsReadyForRequests: Bool {
        true
    }
}

class MockPushMessageHandler: NSObject, PushMessageHandler {
    public func didFailToSend(_ message: ZMMessage) {
        failedToSend.append(message)
    }

    fileprivate(set) var failedToSend: [ZMMessage] = []
}
