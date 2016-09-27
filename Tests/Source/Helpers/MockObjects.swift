//
//  MockStatus.swift
//  WireMessageStrategy
//
//  Created by Sabine Geithner on 23/09/16.
//  Copyright © 2016 Wire Swiss GmbH. All rights reserved.
//

import Foundation
import WireRequestStrategy


class MockClientRegistrationStatus: NSObject, ClientRegistrationDelegate {
    
    var mockClientIsReadyForRequests : Bool = true
    var deletionCalls : Int = 0

    
    /// Whether the current client is ready to use
    public var clientIsReadyForRequests : Bool {
        return mockClientIsReadyForRequests
    }
    
    /// Notify that the current client was deleted remotely
    public func didDetectCurrentClientDeletion() {
        deletionCalls = deletionCalls+1
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


