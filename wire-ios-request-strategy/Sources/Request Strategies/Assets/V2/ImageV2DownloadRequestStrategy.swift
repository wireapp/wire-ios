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

// MARK: - ImageV2DownloadRequestStrategy

public final class ImageV2DownloadRequestStrategy: AbstractRequestStrategy {
    // MARK: Lifecycle

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        let downloadPredicate = NSPredicate { object, _ -> Bool in
            guard let message = object as? ZMAssetClientMessage else {
                return false
            }
            guard message.version < 3 else {
                return false
            }

            let missingMediumImage = message.imageMessageData != nil && !message.hasDownloadedFile && message
                .assetId != nil
            let missingVideoThumbnail = message.fileMessageData != nil && !message.hasDownloadedPreview && message
                .fileMessageData?.thumbnailAssetID != nil

            return (missingMediumImage || missingVideoThumbnail) && message.hasEncryptedAsset
        }

        self.downstreamSync = ZMDownstreamObjectSyncWithWhitelist(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            predicateForObjectsToDownload: downloadPredicate,
            managedObjectContext: managedObjectContext
        )

        registerForWhitelistingNotification()
    }

    // MARK: Public

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        downstreamSync.nextRequest(for: apiVersion)
    }

    // MARK: Internal

    func registerForWhitelistingNotification() {
        token = NotificationInContext.addObserver(
            name: ZMAssetClientMessage.imageDownloadNotificationName,
            context: managedObjectContext.notificationContext,
            object: nil
        ) { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else {
                return
            }
            self?.didRequestToDownloadImage(objectID)
        }
    }

    func didRequestToDownloadImage(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self else {
                return
            }
            guard let object = try? managedObjectContext.existingObject(with: objectID) else {
                return
            }
            guard let message = object as? ZMAssetClientMessage else {
                return
            }
            downstreamSync.whiteListObject(message)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    // MARK: Fileprivate

    fileprivate var downstreamSync: ZMDownstreamObjectSyncWithWhitelist!
    fileprivate let requestFactory = ClientMessageRequestFactory()

    // MARK: Private

    private var token: Any?
}

// MARK: ZMDownstreamTranscoder

extension ImageV2DownloadRequestStrategy: ZMDownstreamTranscoder {
    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        guard
            let message = object as? ZMAssetClientMessage,
            let conversation = message.conversation,
            let cache = managedObjectContext.zm_fileAssetCache
        else {
            return nil
        }

        if let existingData = cache.mediumImageData(for: message) {
            updateMediumImage(forMessage: message, imageData: existingData)
            managedObjectContext.enqueueDelayedSave()
            return nil
        } else {
            switch apiVersion {
            case .v0, .v1:
                if message.imageMessageData != nil {
                    guard let assetId = message.assetId?.transportString() else {
                        return nil
                    }
                    return requestFactory.requestToGetAsset(
                        assetId,
                        inConversation: conversation.remoteIdentifier!,
                        apiVersion: apiVersion
                    )
                } else if message.fileMessageData != nil {
                    guard let assetId = message.fileMessageData?.thumbnailAssetID else {
                        return nil
                    }
                    return requestFactory.requestToGetAsset(
                        assetId,
                        inConversation: conversation.remoteIdentifier!,
                        apiVersion: apiVersion
                    )
                }

            case .v2, .v3, .v4, .v5, .v6:
                // v2 assets are legacy and no longer supported in API v2
                return nil
            }
        }

        return nil
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let message = object as? ZMAssetClientMessage else {
            return
        }
        updateMediumImage(forMessage: message, imageData: response.rawData!)
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let message = object as? ZMAssetClientMessage else {
            return
        }
        message.managedObjectContext?.delete(message)
    }

    fileprivate func updateMediumImage(forMessage message: ZMAssetClientMessage, imageData: Data) {
        storeMediumImage(forMessage: message, imageData: imageData)

        guard let uiMOC = managedObjectContext.zm_userInterface else {
            return
        }
        NotificationDispatcher.notifyNonCoreDataChanges(
            objectID: message.objectID,
            changedKeys: [#keyPath(ZMAssetClientMessage.hasDownloadedFile)],
            uiContext: uiMOC
        )
    }

    fileprivate func storeMediumImage(
        forMessage message: ZMAssetClientMessage,
        imageData: Data
    ) {
        guard let cache = managedObjectContext.zm_fileAssetCache else {
            return
        }

        if message.hasEncryptedAsset {
            let sha256: Data?

            if message.fileMessageData != nil {
                let remote = message.underlyingMessage?.assetData?.preview.remote
                sha256 = remote?.sha256
            } else if message.imageMessageData != nil {
                let imageAsset = message.mediumGenericMessage?.imageAssetData
                sha256 = imageAsset?.sha256
            } else {
                sha256 = nil
            }

            if let sha256, imageData.zmSHA256Digest() != sha256 {
                if message.imageMessageData != nil {
                    managedObjectContext.delete(message)
                }

                return
            }

            cache.storeEncryptedMediumImage(
                data: imageData,
                for: message
            )
        } else {
            cache.storeMediumImage(
                data: imageData,
                for: message
            )
        }
    }
}
