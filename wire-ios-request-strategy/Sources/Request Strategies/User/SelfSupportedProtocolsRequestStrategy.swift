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

public final class SelfSupportedProtocolsRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder {

    // Slow Sync

    private unowned var syncStatus: SyncProgress

    private let syncPhase: SyncPhase = .updateSelfSupportedProtocols

    private var isSlowSyncing: Bool { syncStatus.currentSyncPhase == syncPhase }

    // Requests

    private lazy var requestSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)

    let userRepository: UserRepositoryInterface

    required public init(
        context: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncStatus: SyncProgress,
        userRepository: UserRepositoryInterface
    ) {
        self.syncStatus = syncStatus
        self.userRepository = userRepository

        super.init(withManagedObjectContext: context, applicationStatus: applicationStatus)

        configuration = [.allowsRequestsDuringSlowSync]
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard isSlowSyncing else {
            return nil
        }

        // TODO: update self user protocols
        let user = userRepository.selfUser()
        if user.supportedProtocols.isEmpty {
            user.supportedProtocols = [.proteus]
        }

        requestSync.readyForNextRequestIfNotBusy()
        return requestSync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard sync == requestSync else {
            return nil
        }

        let supportedProtocols = userRepository.selfUser().supportedProtocols
        assert(supportedProtocols.isEmpty, "expected supported protocols to be set before updating")

        let transportBuilder = SelfSupportedProtocolsBuilder(
            apiVersion: apiVersion,
            supportedProtocols: supportedProtocols
        )
        return transportBuilder.buildTransportRequest()
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        // no-op
        debugPrint("did receive")

        managedObjectContext.perform {
            self.syncStatus.finishCurrentSyncPhase(phase: self.syncPhase)
        }
    }
}
