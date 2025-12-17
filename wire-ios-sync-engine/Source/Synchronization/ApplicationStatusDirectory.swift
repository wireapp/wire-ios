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

import CoreData
import Foundation
import WireDomain
import WireRequestStrategy

@objcMembers
public final class ApplicationStatusDirectory: NSObject, ApplicationStatus {

    public let userProfileImageUpdateStatus: UserProfileImageUpdateStatus
    public let userProfileUpdateStatus: UserProfileUpdateStatus
    public let clientRegistrationStatus: ZMClientRegistrationStatus
    public let clientUpdateStatus: ClientUpdateStatus
    public let proxiedRequestStatus: ProxiedRequestsStatus
    public let operationStatus: OperationStatus
    public let requestCancellation: ZMRequestCancellation
    public let teamInvitationStatus: TeamInvitationStatus
    public let assetDeletionStatus: AssetDeletionStatus

    fileprivate var callInProgressObserverToken: Any?

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        cookieStorage: ZMPersistentCookieStorage,
        requestCancellation: ZMRequestCancellation,
        application: ZMApplication,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        isSyncV2Enabled: Bool,
        localDomain: String?,
        isBackendMLSEnabled: Bool
    ) {
        self.requestCancellation = requestCancellation
        self.operationStatus = OperationStatus()
        self.teamInvitationStatus = TeamInvitationStatus()
        operationStatus.isInBackground = application.applicationState == .background
    
        self.userProfileUpdateStatus = UserProfileUpdateStatus(managedObjectContext: managedObjectContext)
        self.clientUpdateStatus = ClientUpdateStatus(syncManagedObjectContext: managedObjectContext)
        self.clientRegistrationStatus = ZMClientRegistrationStatus(
            context: managedObjectContext,
            cookieProvider: cookieStorage,
            coreCryptoProvider: coreCryptoProvider,
            localDomain: localDomain,
            isBackendMLSEnabled: isBackendMLSEnabled
        )
        self.proxiedRequestStatus = ProxiedRequestsStatus(requestCancellation: requestCancellation)
        self.userProfileImageUpdateStatus = UserProfileImageUpdateStatus(managedObjectContext: managedObjectContext)
        self.assetDeletionStatus = AssetDeletionStatus(provider: managedObjectContext, queue: managedObjectContext)
        super.init()

        self.callInProgressObserverToken = NotificationInContext.addObserver(
            name: CallStateObserver.CallInProgressNotification,
            context: managedObjectContext.notificationContext
        ) { [weak self] note in
            managedObjectContext.performGroupedBlock {
                if let callInProgress = note.userInfo[CallStateObserver.CallInProgressKey] as? Bool {
                    self?.operationStatus.hasOngoingCall = callInProgress
                }
            }
        }
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        clientRegistrationStatus
    }

    public var operationState: OperationState {
        switch operationStatus.operationState {
        case .foreground:
            .foreground
        case .background, .backgroundCall, .backgroundFetch, .backgroundTask:
            .background
        }
    }

    public var synchronizationState: SynchronizationState {
        if !clientRegistrationStatus.clientIsReadyForRequests {
            .unauthenticated
        } else {
            .online
        }
    }

}
