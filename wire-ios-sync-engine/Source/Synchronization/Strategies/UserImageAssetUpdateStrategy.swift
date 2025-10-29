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

import Foundation
import WireLogging
import WireRequestStrategy

enum AssetTransportError: Error {
    case invalidLength
    case assetTooLarge
    case other(Error?)

    init(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (400, .some("invalid-length")):
            self = .invalidLength
        case (413, .some("client-error")):
            self = .assetTooLarge
        default:
            self = .other(response.transportSessionError)
        }
    }
}

public final class UserImageAssetUpdateStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource,
    ZMSingleRequestTranscoder, ZMDownstreamTranscoder {
    let requestFactory = AssetRequestFactory()
    var upstreamRequestSyncs = [ProfileImageSize: ZMSingleRequestSync]()
    var deleteRequestSync: ZMSingleRequestSync?
    var downstreamRequestSyncs = [ProfileImageSize: ZMDownstreamObjectSyncWithWhitelist]()
    let moc: NSManagedObjectContext
    weak var imageUploadStatus: UserProfileImageUploadStatusProtocol?

    fileprivate var observers: [Any] = []

    private let localDomain: String?
    private let isCloudDomain: Bool

    private let featureRepository: LegacyFeatureRepository

    private var shouldUploadExtraMetaData: Bool {
        guard !isCloudDomain else { return false }
        return managedObjectContext.performAndWait {
            featureRepository.fetchAssetAuditLog().status == .enabled
        }
    }

    @objc
    public convenience init(
        managedObjectContext: NSManagedObjectContext,
        applicationStatusDirectory: ApplicationStatusDirectory,
        userProfileImageUpdateStatus: UserProfileImageUpdateStatus,
        localDomain: String?,
        isCloudDomain: Bool
    ) {
        self.init(
            managedObjectContext: managedObjectContext,
            applicationStatus: applicationStatusDirectory,
            imageUploadStatus: userProfileImageUpdateStatus,
            localDomain: localDomain,
            isCloudDomain: isCloudDomain
        )
    }

    init(
        managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        imageUploadStatus: UserProfileImageUploadStatusProtocol,
        localDomain: String?,
        isCloudDomain: Bool
    ) {
        self.moc = managedObjectContext
        self.imageUploadStatus = imageUploadStatus
        self.localDomain = localDomain
        self.isCloudDomain = isCloudDomain
        self.featureRepository = LegacyFeatureRepository(context: managedObjectContext)
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        downstreamRequestSyncs[.preview] = whitelistUserImageSync(for: .preview)
        downstreamRequestSyncs[.complete] = whitelistUserImageSync(for: .complete)
        downstreamRequestSyncs.forEach { _, sync in
            sync.whiteListObject(ZMUser.selfUser(in: managedObjectContext))
        }

        upstreamRequestSyncs[.preview] = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: moc)
        upstreamRequestSyncs[.complete] = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: moc)
        self.deleteRequestSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: moc)

        observers.append(
            NotificationInContext.addObserver(
                name: .userDidRequestCompleteAsset,
                context: managedObjectContext.notificationContext,
                using: { [weak self] in self?.requestAssetForNotification(note: $0) }
            )
        )
        observers.append(
            NotificationInContext.addObserver(
                name: .userDidRequestPreviewAsset,
                context: managedObjectContext.notificationContext,
                using: { [weak self] in self?.requestAssetForNotification(note: $0) }
            )
        )
    }

    fileprivate func whitelistUserImageSync(for size: ProfileImageSize) -> ZMDownstreamObjectSyncWithWhitelist {
        let predicate: NSPredicate = switch size {
        case .preview:
            ZMUser.previewImageDownloadFilter
        case .complete:
            ZMUser.completeImageDownloadFilter
        }

        return ZMDownstreamObjectSyncWithWhitelist(
            transcoder: self,
            entityName: ZMUser.entityName(),
            predicateForObjectsToDownload: predicate,
            managedObjectContext: moc
        )
    }

    func size(for requestSync: ZMDownstreamObjectSyncWithWhitelist) -> ProfileImageSize? {
        for (size, sync) in downstreamRequestSyncs where sync === requestSync {
            return size
        }
        return nil
    }

    func size(for requestSync: ZMSingleRequestSync) -> ProfileImageSize? {
        for (size, sync) in upstreamRequestSyncs where sync === requestSync {
            return size
        }
        return nil
    }

    func requestAssetForNotification(note: NotificationInContext) {
        moc.performGroupedBlock {
            guard let objectID = note.object as? NSManagedObjectID,
                  let object = self.moc.object(with: objectID) as? ZMManagedObject
            else { return }

            switch note.name {
            case .userDidRequestPreviewAsset:
                self.downstreamRequestSyncs[.preview]?.whiteListObject(object)
            case .userDidRequestCompleteAsset:
                self.downstreamRequestSyncs[.complete]?.whiteListObject(object)
            default:
                break
            }

            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        for size in ProfileImageSize.allSizes {
            let requestSync = downstreamRequestSyncs[size]
            if let request = requestSync?.nextRequest(for: apiVersion) {
                return request
            }
        }

        guard let updateStatus = imageUploadStatus else { return nil }

        // There are assets added for deletion
        if updateStatus.hasAssetToDelete() {
            deleteRequestSync?.readyForNextRequestIfNotBusy()
            return deleteRequestSync?.nextRequest(for: apiVersion)
        }

        let sync = ProfileImageSize.allSizes.filter(updateStatus.hasImageToUpload)
            .compactMap { upstreamRequestSyncs[$0] }.first
        sync?.readyForNextRequestIfNotBusy()
        return sync?.nextRequest(for: apiVersion)
    }

    // MARK: - ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        Array(downstreamRequestSyncs.values)
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest! {
        guard let whitelistSync = downstreamSync as? ZMDownstreamObjectSyncWithWhitelist else { return nil }
        guard let user = object as? ZMUser else { return nil }
        guard let size = size(for: whitelistSync) else { return nil }

        let remoteId: String? = switch size {
        case .preview:
            user.previewProfileAssetIdentifier
        case .complete:
            user.completeProfileAssetIdentifier
        }
        guard let assetId = remoteId else { return nil }

        let path: String
        switch apiVersion {

        case .v0:
            path = "/assets/v3/\(assetId)"

        case .v1:
            let domain = if let domain = user.domain, !domain.isEmpty { domain } else { localDomain }
            guard let domain else { return nil }

            path = "/assets/v4/\(domain)/\(assetId)"

        case .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12:
            let domain = if let domain = user.domain, !domain.isEmpty { domain } else { localDomain }
            guard let domain else { return nil }

            path = "/assets/\(domain)/\(assetId)"
        }

        return ZMTransportRequest.imageGet(fromPath: path, apiVersion: apiVersion.rawValue)
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let whitelistSync = downstreamSync as? ZMDownstreamObjectSyncWithWhitelist else { return }
        guard let user = object as? ZMUser else { return }

        switch size(for: whitelistSync) {
        case .preview?: user.previewProfileAssetIdentifier = nil
        case .complete?: user.completeProfileAssetIdentifier = nil
        default: break
        }
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let whitelistSync = downstreamSync as? ZMDownstreamObjectSyncWithWhitelist else { return }
        guard let user = object as? ZMUser else { return }
        guard let size = size(for: whitelistSync) else { return }

        user.setImage(data: response.rawData, size: size)
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        if let size = size(for: sync), let image = imageUploadStatus?.consumeImage(for: size) {
            var extraMetaData: AssetRequestFactory.AssetAuditLogMetaData?
            if shouldUploadExtraMetaData {
                guard
                    // As per the spec: there's no conversation so we use a null id instead.
                    let nullID = UUID(uuidString: "00000000-0000-0000-0000-000000000000"),
                    let localDomain
                else {
                    WireLogger.assets.warn(
                        "should include extra metadata for profile image but not able to",
                        attributes: .safePublic
                    )
                    return nil
                }

                let image = SendableImage(
                    name: nil,
                    utType: nil,
                    data: image
                )

                extraMetaData = .init(
                    conversationID: QualifiedID(uuid: nullID, domain: localDomain),
                    fileName: image.name,
                    mimeType: image.utType?.preferredMIMEType
                )
            }

            let request = requestFactory.upstreamRequestForAsset(
                withData: image,
                shareable: true,
                retention: .eternal,
                assetAuditLogMetaData: extraMetaData,
                apiVersion: apiVersion
            )

            // [WPB-7392] through a refactoring the `contentHintForRequestLoop` was seperated form
            // `addContentDebugInformation`.
            // Not clear if it is necessary to set `contentHintForRequestLoop` here, but keep the original behavior.
            request?.addContentDebugInformation("Uploading to /assets/V3: [\(size)]  [\(image)] ")
            request?.contentHintForRequestLoop += "Uploading to /assets/V3: [\(size)]  [\(image)] "

            return request
        } else if sync === deleteRequestSync {
            if let assetId = imageUploadStatus?.consumeAssetToDelete() {
                let path = "/assets/v3/\(assetId)"
                return ZMTransportRequest(path: path, method: .delete, payload: nil, apiVersion: apiVersion.rawValue)
            }
        }
        return nil
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard let size = size(for: sync) else { return }
        guard response.result == .success else {
            let error = AssetTransportError(response: response)
            imageUploadStatus?.uploadingFailed(imageSize: size, error: error)
            return
        }
        guard let payload = response.payload?.asDictionary(),
              let assetId = payload["key"] as? String else { fatal("No asset ID present in payload") }
        imageUploadStatus?.uploadingDone(imageSize: size, assetId: assetId)
    }
}
