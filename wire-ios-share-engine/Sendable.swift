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
import ZMCDataModel

/// A object that can be sent, in progress, or failed, optionally tracking the sending progress
public protocol Sendable {
    
    /// The state of the delivery
    var deliveryState : ZMDeliveryState { get }

    /// The progress of the delivery, from 0 to 1.
    /// It will be nil if the progress can not be tracked.
    /// It will be 1 when the delivery is completed.
    var deliveryProgress : Float? { get }
    
    /// Adds an observer for a change in status or delivery progress
    /// - returns: the observable token
    func registerObserverToken(_ observer: SendableObserver) -> SendableObserverToken
    
    /// Removes an observer token
    func remove(_ observerToken: SendableObserverToken)
    
    /// Expire message sending
    func cancel()
}

/// An observer of the progress of a Sendable
public protocol SendableObserver {
    
    /// Either the delivery state or the delivery progress changed
    func onDeliveryChanged()
    
}

/// Wrapper around an observer token for SendableObserver
public struct SendableObserverToken {
    let token : AnyObject
}
