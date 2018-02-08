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


@objc public protocol ClientRegistrationDelegate : NSObjectProtocol  {

    /// Returns true if the client is registered
    var clientIsReadyForRequests : Bool { get }
    
    /// Notify that the current client was deleted remotely
    func didDetectCurrentClientDeletion()

}


@objc public protocol DeliveryConfirmationDelegate : NSObjectProtocol {
    /// If set to false, no delivery receipts are sent
    static var sendDeliveryReceipts : Bool { get }
    
    /// If set to true, we need to send delivery receipts
    var needsToSyncMessages : Bool { get }
    
    /// Adds the messageNonce to a collection of messages to be synced and starts a background activity for sending the request
    func needsToConfirmMessage(_ messageNonce: UUID)
    
    /// Removes the messageNonce from a collection of messages to be synced and ends the background activity for sending the request
    func didConfirmMessage(_ messageNonce: UUID)
}


