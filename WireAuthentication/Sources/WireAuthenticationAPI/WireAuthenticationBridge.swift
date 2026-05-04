//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import Foundation

/// A object that facilitates intermodule communication, both **inbound**
/// (from outside into this module) and **outbound** (from inside this module
/// to the external world).

public final class WireAuthenticationBridge {

    private let inboundSubject = PassthroughSubject<InboundEvent, Never>()
    private let outboundSubject = PassthroughSubject<OutboundEvent, Never>()

    public var inboundEvents: AnyPublisher<InboundEvent, Never> {
        inboundSubject.eraseToAnyPublisher()
    }

    public var outboundEvents: AnyPublisher<OutboundEvent, Never> {
        outboundSubject.eraseToAnyPublisher()
    }

    public init() {}

    public func sendOutboundEvent(_ event: OutboundEvent) {
        outboundSubject.send(event)
    }

    public func sendInboundEvent(_ event: InboundEvent) {
        inboundSubject.send(event)
    }

    /// Events originating within the feature module and
    /// communicated outside.

    public enum OutboundEvent {

        case userAuthenticated(AuthenticationResult, RegistrationAnalyticsTrackingConsent)
        case exitFlowRequested
        case logoutRequested(deleteData: Bool)

    }

    /// Events originating outside the feature module and
    /// communicated inside.

    public enum InboundEvent {

        case didRewindToThisView
        case backendSwitchRequested(configURL: URL)
        case updateAnotherAccountExistence(newValue: Bool)

    }

}
