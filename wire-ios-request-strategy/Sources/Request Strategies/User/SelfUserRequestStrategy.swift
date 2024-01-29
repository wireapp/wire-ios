////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public final class SelfUserRequestStrategy: AbstractRequestStrategy {

    // MARK: - Properties

    private let transcoder = Transcoder()
    private let upstreamSync: ZMUpstreamModifiedObjectSync

    // MARK: - Life cycle

    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        upstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: transcoder,
            entityName: ZMUser.entityName(),
            keysToSync: [ZMUser.supportedProtocolsKey],
            managedObjectContext: managedObjectContext
        )

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )
    }

    // MARK: - Request

    public override func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        upstreamSync.nextRequest(for: apiVersion)
    }

}

private extension SelfUserRequestStrategy {

    final class Transcoder: NSObject, ZMUpstreamTranscoder {

        func shouldCreateRequest(
            toSyncObject managedObject: ZMManagedObject,
            forKeys keys: Set<String>,
            withSync sync: Any,
            apiVersion: APIVersion
        ) -> Bool {
            guard keys.contains(ZMUser.supportedProtocolsKey) else {
                return false
            }

            return apiVersion >= .v4
        }

        func request(
            forUpdating managedObject: ZMManagedObject,
            forKeys keys: Set<String>,
            apiVersion: APIVersion
        ) -> ZMUpstreamRequest? {
            guard
                apiVersion >= .v4,
                keys.contains(ZMUser.supportedProtocolsKey),
                let user = managedObject as? ZMUser
            else {
                return nil
            }

            var payload = [AnyHashable: Any]()
            payload["supported_protocols"] = user.supportedProtocols.map(\.rawValue)

            let request = ZMTransportRequest(
                path: "/self/supported-protocols",
                method: .put,
                payload: payload as ZMTransportData,
                apiVersion: apiVersion.rawValue
            )

            return ZMUpstreamRequest(
                keys: keys,
                transportRequest: request
            )
        }

        func shouldRetryToSyncAfterFailed(
            toUpdate managedObject: ZMManagedObject,
            request upstreamRequest: ZMUpstreamRequest,
            response: ZMTransportResponse,
            keysToParse keys: Set<String>
        ) -> Bool {
            WireLogger.mls.error("failed to upload supported protocols: \(response.errorInfo)")
            return false
        }

        func updateUpdatedObject(
            _ managedObject: ZMManagedObject,
            requestUserInfo: [AnyHashable: Any]? = nil,
            response: ZMTransportResponse,
            keysToParse: Set<String>
        ) -> Bool {
            return false
        }

        func shouldProcessUpdatesBeforeInserts() -> Bool {
            return false
        }

        func request(
            forInserting managedObject: ZMManagedObject,
            forKeys keys: Set<String>?,
            apiVersion: APIVersion
        ) -> ZMUpstreamRequest? {
            return nil
        }

        func updateInsertedObject(
            _ managedObject: ZMManagedObject,
            request upstreamRequest: ZMUpstreamRequest,
            response: ZMTransportResponse
        ) {
            // no-op
        }

        func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
            return nil
        }

    }

}

extension SelfUserRequestStrategy: ZMContextChangeTrackerSource {

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [upstreamSync]
    }

}
