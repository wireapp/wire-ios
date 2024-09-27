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

private let zmLog = ZMSLog(tag: "terminate federation")

// MARK: - TerminateFederationRequestStrategy

@objcMembers
public final class TerminateFederationRequestStrategy: AbstractRequestStrategy {
    // MARK: Lifecycle

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        self.federationTerminationManager = FederationTerminationManager(with: managedObjectContext)

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket,
            .allowsRequestsWhileInBackground,
        ]
    }

    // MARK: Public

    // MARK: - Request

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        nil
    }

    // MARK: Internal

    // MARK: - Properties

    var federationTerminationManager: FederationTerminationManagerInterface
}

// MARK: ZMEventConsumer

extension TerminateFederationRequestStrategy: ZMEventConsumer {
    public func processEvents(
        _ events: [ZMUpdateEvent],
        liveEvents: Bool,
        prefetchResult: ZMFetchRequestBatchResult?
    ) {
        events.forEach(processEvent)
    }

    private func processEvent(_ event: ZMUpdateEvent) {
        let decoder = EventPayloadDecoder()

        switch event.type {
        case .federationDelete:
            if let payload = try? decoder.decode(Payload.FederationDelete.self, from: event.payload) {
                federationTerminationManager.handleFederationTerminationWith(payload.domain)
            }

        case .federationConnectionRemoved:
            if let payload = try? decoder.decode(Payload.ConnectionRemoved.self, from: event.payload),
               payload.domains.count == 2,
               let firstDomain = payload.domains.first,
               let secondDomain = payload.domains.last {
                federationTerminationManager.handleFederationTerminationBetween(
                    firstDomain,
                    otherDomain: secondDomain
                )
            }

        default:
            break
        }
    }
}

extension Payload {
    /// The domain that the self domain has stopped federate with.
    struct FederationDelete: Codable {
        let domain: String
        let type: String
    }

    /// The list of domains that have terminated federation with each other.
    struct ConnectionRemoved: Codable {
        let domains: [String]
        let type: String
    }
}
