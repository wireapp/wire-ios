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
import WireRequestStrategy

final class ApplicationStatusDirectory: ApplicationStatus {
    // MARK: - Properties

    let transportSession: ZMTransportSession

    /// The authentication status used to verify a user is authenticated.

    public let authenticationStatus: AuthenticationStatusProvider

    /// The client registration status used to lookup if a user has registered a self client.

    public let clientRegistrationStatus: ClientRegistrationDelegate

    public let linkPreviewDetector: LinkPreviewDetectorType

    public var pushNotificationStatus: PushNotificationStatus

    // MARK: - Life cycle

    public convenience init(
        syncContext: NSManagedObjectContext,
        transportSession: ZMTransportSession,
        lastEventIDRepository: LastEventIDRepositoryInterface
    ) {
        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)
        let linkPreviewDetector = LinkPreviewDetector()

        self.init(
            managedObjectContext: syncContext,
            transportSession: transportSession,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: clientRegistrationStatus,
            linkPreviewDetector: linkPreviewDetector,
            lastEventIDRepository: lastEventIDRepository
        )
    }

    public init(
        managedObjectContext: NSManagedObjectContext,
        transportSession: ZMTransportSession,
        authenticationStatus: AuthenticationStatusProvider,
        clientRegistrationStatus: ClientRegistrationStatus,
        linkPreviewDetector: LinkPreviewDetectorType,
        lastEventIDRepository: LastEventIDRepositoryInterface
    ) {
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.linkPreviewDetector = linkPreviewDetector
        self.pushNotificationStatus = PushNotificationStatus(
            managedObjectContext: managedObjectContext,
            lastEventIDRepository: lastEventIDRepository
        )
    }

    // MARK: - Methods

    public var synchronizationState: SynchronizationState {
        if clientRegistrationStatus.clientIsReadyForRequests {
            .online
        } else {
            .unauthenticated
        }
    }

    public var operationState: OperationState {
        .background
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        clientRegistrationStatus
    }

    public var requestCancellation: ZMRequestCancellation {
        transportSession
    }

    func requestResyncResources() {
        // We don't resync Resources in the notification engine.
    }
}
