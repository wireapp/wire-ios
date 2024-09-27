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
import WireDomain
import WireRequestStrategy

public final class SelfSupportedProtocolsRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder {
    // MARK: Lifecycle

    // MARK: - Initializers

    public required init(
        context: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncProgress: SyncProgress,
        selfUserProvider: SelfUserProviderProtocol
    ) {
        self.syncProgress = syncProgress
        self.selfUserProvider = selfUserProvider

        super.init(withManagedObjectContext: context, applicationStatus: applicationStatus)

        configuration = [.allowsRequestsDuringSlowSync]
    }

    // MARK: Public

    // MARK: - Functions

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard isSlowSyncing else {
            return nil
        }

        WireLogger.sync.info("start slow sync phase: \(syncPhase.description)")

        requestSync.readyForNextRequestIfNotBusy()
        return requestSync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard sync == requestSync, isSlowSyncing else {
            return nil
        }

        let service = SupportedProtocolsService(
            featureRepository: FeatureRepository(context: managedObjectContext),
            selfUserProvider: selfUserProvider
        )

        let calculatedProtocols = service.calculateSupportedProtocols()
        assert(!calculatedProtocols.isEmpty, "calculated empty supported protocols to be set before updating")

        let transportBuilder = SelfSupportedProtocolsRequestBuilder(
            apiVersion: apiVersion,
            supportedProtocols: calculatedProtocols
        )

        guard let request = transportBuilder.buildTransportRequest() else {
            // finish sync instead of fail, because we can never execute a request
            WireLogger.sync.warn(
                "can not create transport request, one reason could be an unsupported api version!",
                attributes: .safePublic
            )
            finishSlowSync()
            return nil
        }

        return request
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard isSlowSyncing else {
            // skip result if we are not in the slow sync...
            assertionFailure("expected response during slow sync phase!")
            WireLogger.sync.error(
                "received response, but expected during slow sync phase '\(syncPhase.description)'!",
                attributes: .safePublic
            )
            return
        }

        let service = SupportedProtocolsService(
            featureRepository: FeatureRepository(context: managedObjectContext),
            selfUserProvider: selfUserProvider
        )

        switch response.result {
        case .success:
            let selfUser = selfUserProvider.fetchSelfUser()
            selfUser.supportedProtocols = service.calculateSupportedProtocols()
            finishSlowSync()

        default:
            failSlowSync()
        }
    }

    // MARK: Private

    // MARK: - Properties

    // Slow Sync

    private unowned var syncProgress: SyncProgress

    private let syncPhase: SyncPhase = .updateSelfSupportedProtocols

    // Requests

    private lazy var requestSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)

    private let selfUserProvider: SelfUserProviderProtocol

    private var isSlowSyncing: Bool { syncProgress.currentSyncPhase == syncPhase }

    // MARK: Sync Progress

    private func finishSlowSync() {
        WireLogger.sync.info("finished slow sync phase '\(syncPhase.description)'!")
        managedObjectContext.performAndWait {
            self.syncProgress.finishCurrentSyncPhase(phase: self.syncPhase)
        }
    }

    private func failSlowSync() {
        WireLogger.sync.error(
            "failed slow sync phase '\(syncPhase.description)'!",
            attributes: .safePublic
        )
        managedObjectContext.performAndWait {
            self.syncProgress.failCurrentSyncPhase(phase: self.syncPhase)
        }
    }
}
