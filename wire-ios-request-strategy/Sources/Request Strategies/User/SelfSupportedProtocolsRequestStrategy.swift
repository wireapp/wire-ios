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

    // MARK: - Properties

    // Slow Sync

    private unowned var syncProgress: SyncProgress

    private let syncPhase: SyncPhase = .updateSelfSupportedProtocols

    private var isSlowSyncing: Bool { syncProgress.currentSyncPhase == syncPhase }

    // Requests

    private lazy var requestSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)

    private let userRepository: UserRepositoryInterface

    // MARK: - Initializers

    required public init(
        context: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncProgress: SyncProgress,
        userRepository: UserRepositoryInterface
    ) {
        self.syncProgress = syncProgress
        self.userRepository = userRepository

        super.init(withManagedObjectContext: context, applicationStatus: applicationStatus)

        configuration = [.allowsRequestsDuringSlowSync]
    }

    // MARK: - Functions

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard isSlowSyncing else {
            return nil
        }

        WireLogger.sync.info("start slow sync phase: \(syncPhase.description)")

        // Update supported protocols on user self.
        // Unfortunately this method is called often and we only want to update once, so we check the status.
        if requestSync.status != .inProgress {
            WireLogger.sync.info("slow sync now updates supported protocols")
            let service = SupportedProtocolsService(
                featureRepository: FeatureRepository(context: managedObjectContext),
                userRepository: userRepository
            )
            service.updateSupportedProtocols()
        }

        requestSync.readyForNextRequestIfNotBusy()
        return requestSync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard sync == requestSync, isSlowSyncing else {
            return nil
        }

        let supportedProtocols = userRepository.selfUser().supportedProtocols
        assert(!supportedProtocols.isEmpty, "expected supported protocols to be set before updating")

        let transportBuilder = SelfSupportedProtocolsRequestBuilder(
            apiVersion: apiVersion,
            supportedProtocols: supportedProtocols
        )
        return transportBuilder.buildTransportRequest()
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard isSlowSyncing else {
            // skip result if we are not in the slow sync...
            assertionFailure("expected response during slow sync phase!")
            WireLogger.sync.error("received response, but expected during slow sync phase '\(syncPhase.description)'!")
            return
        }

        switch response.result {
        case .success:
            WireLogger.sync.error("finished slow sync phase '\(syncPhase.description)'!")
            managedObjectContext.perform {
                self.syncProgress.finishCurrentSyncPhase(phase: self.syncPhase)
            }
        default:
            WireLogger.sync.error("failed slow sync phase '\(syncPhase.description)'!")
            managedObjectContext.perform {
                self.syncProgress.failCurrentSyncPhase(phase: self.syncPhase)
            }
        }
    }
}
