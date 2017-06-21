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


import Foundation
import WireRequestStrategy
import WireMessageStrategy
import WireDataModel

public class MockApplicationStatus : NSObject, ApplicationStatus {

    
    public var deliveryConfirmation: DeliveryConfirmationDelegate {
        return self.mockConfirmationStatus
    }
    
    public var requestCancellation : ZMRequestCancellation {
        return self.mockTaskCancellationDelegate
    }
    
    public var clientRegistrationDelegate : ClientRegistrationDelegate {
        return self.mockClientRegistrationStatus
    }

    public var notificationFetchStatus = BackgroundNotificationFetchStatus.done

    public let mockConfirmationStatus = MockConfirmationStatus()
    public let mockTaskCancellationDelegate = MockTaskCancellationDelegate()
    public var mockClientRegistrationStatus = MockClientRegistrationStatus()
    
    public var mockSynchronizationState : SynchronizationState = .unauthenticated
    
    public var synchronizationState: SynchronizationState {
        return mockSynchronizationState
    }

    public var mockOperationState : OperationState = .foreground
    
    public var operationState: OperationState {
        return mockOperationState
    }
        
    public var cancelledIdentifiers : [ZMTaskIdentifier] {
        return mockTaskCancellationDelegate.cancelledIdentifiers
    }
    
    public var deletionCalls : Int {
        return mockClientRegistrationStatus.deletionCalls
    }

    public var messagesToConfirm : Set<UUID> {
        return mockConfirmationStatus.messagesToConfirm
    }
    
    public var messagesConfirmed : Set<UUID> {
        return mockConfirmationStatus.messagesConfirmed
    }
    
}


public class MockTaskCancellationDelegate: NSObject, ZMRequestCancellation {
    public var cancelledIdentifiers = [ZMTaskIdentifier]()
    
    public func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }
}


public class MockClientRegistrationStatus: NSObject, ClientRegistrationDelegate {
    
    public var deletionCalls : Int = 0
    
    /// Notify that the current client was deleted remotely
    public func didDetectCurrentClientDeletion() {
        deletionCalls = deletionCalls+1
    }
    
    public var clientIsReadyForRequests: Bool {
        return true
    }
}


@objc public class MockConfirmationStatus : NSObject, DeliveryConfirmationDelegate {
    
    public private (set) var messagesToConfirm = Set<UUID>()
    public private (set) var messagesConfirmed = Set<UUID>()

    public static var sendDeliveryReceipts: Bool {
        return true
    }
    
    public var needsToSyncMessages: Bool {
        return true
    }
    
    public func needsToConfirmMessage(_ messageNonce: UUID) {
        messagesToConfirm.insert(messageNonce)
    }
    
    public func didConfirmMessage(_ messageNonce: UUID) {
        messagesConfirmed.insert(messageNonce)
    }
}

class MockPushMessageHandler: NSObject, PushMessageHandler {
    
    public func didFailToSend(_ message: ZMMessage) {
        failedToSend.append(message)
    }
    
    public func process(_ message: ZMMessage) {
        processedMessages.append(message)
    }
    
    public func process(_ genericMessage: ZMGenericMessage) {
        processedGenericMessages.append(genericMessage)
    }
    
    fileprivate(set) var failedToSend: [ZMMessage] = []
    fileprivate(set) var processedMessages: [ZMMessage] = []
    fileprivate(set) var processedGenericMessages: [ZMGenericMessage] = []
}
