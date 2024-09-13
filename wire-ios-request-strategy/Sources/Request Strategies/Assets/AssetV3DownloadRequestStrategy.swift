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

import WireImages
import WireTransport

private let zmLog = ZMSLog(tag: "Asset V3")

@objcMembers
public final class AssetV3DownloadRequestStrategy: AbstractRequestStrategy, ZMDownstreamTranscoder,
    ZMContextChangeTrackerSource {
    private let requestFactory = AssetDownloadRequestFactory()

    fileprivate var assetDownstreamObjectSync: ZMDownstreamObjectSyncWithWhitelist!
    private var notificationTokens: [Any] = []

    private typealias DecryptionKeys = (otrKey: Data, sha256: Data)

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        configuration = .allowsRequestsWhileOnline

        let downloadPredicate = NSPredicate { object, _ -> Bool in
            guard let message = object as? ZMAssetClientMessage else { return false }
            guard message.version >= 3 else { return false }

            return !message.hasDownloadedFile && message.transferState == .uploaded && message.isDownloading && message
                .underlyingMessage?.assetData?.hasUploaded == true
        }

        self.assetDownstreamObjectSync = ZMDownstreamObjectSyncWithWhitelist(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            predicateForObjectsToDownload: downloadPredicate,
            managedObjectContext: managedObjectContext
        )

        registerForCancellationNotification()
        registerForWhitelistingNotification()
    }

    func registerForCancellationNotification() {
        notificationTokens.append(NotificationInContext.addObserver(
            name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
            context: managedObjectContext.notificationContext,
            object: nil
        ) { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.cancelOngoingRequestForAssetClientMessage(objectID)
        })
    }

    func registerForWhitelistingNotification() {
        notificationTokens.append(NotificationInContext.addObserver(
            name: ZMAssetClientMessage.assetDownloadNotificationName,
            context: managedObjectContext.notificationContext,
            object: nil
        ) { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.didRequestToDownloadAsset(objectID)
        })
    }

    func didRequestToDownloadAsset(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self else { return }
            guard let object = try? managedObjectContext.existingObject(with: objectID) else { return }
            guard let message = object as? ZMAssetClientMessage, !message.hasDownloadedFile else { return }
            message.isDownloading = true
            assetDownstreamObjectSync.whiteListObject(message)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    func cancelOngoingRequestForAssetClientMessage(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self  else { return }
            guard let message = managedObjectContext.registeredObject(for: objectID) as? ZMAssetClientMessage
            else { return }
            guard message.version >= 3 else { return }
            guard let identifier = message.associatedTaskIdentifier else { return }
            applicationStatus?.requestCancellation.cancelTask(with: identifier)
            message.isDownloading = false
            message.associatedTaskIdentifier = nil
        }
    }

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        assetDownstreamObjectSync.nextRequest(for: apiVersion)
    }

    fileprivate func handleResponse(
        _ response: ZMTransportResponse,
        forMessage assetClientMessage: ZMAssetClientMessage
    ) {
        var decryptSuccess = false

        assetClientMessage.isDownloading = false

        if response.result == .success {
            decryptSuccess = storeAndDecrypt(data: response.rawData!, for: assetClientMessage)
        }
//        When the backend redirects to the cloud service to get the image, it could be that the
//        network bandwidth of the device is really bad. If the time interval is pretty long before
//        the connectivity returns, the cloud responds with an error having status code 403
//        -> retry the image request and do not delete the asset client message.
        else if response.result == .permanentError, response.httpStatus != 403 {
            zmLog.debug("asset unavailable on remote (\(response.httpStatus)), deleting")
            managedObjectContext.delete(assetClientMessage)
        } else {
            zmLog.debug("error downloading asset (\(response.httpStatus))")
            return
        }

        if !decryptSuccess {
            zmLog.debug("asset unavailable to decrypt, deleting")
            managedObjectContext.delete(assetClientMessage)
        }

        // we've just downloaded some data, we need to refresh the category of the message.
        assetClientMessage.updateCategoryCache()

        if decryptSuccess {
            NotificationDispatcher.notifyNonCoreDataChanges(
                objectID: assetClientMessage.objectID,
                changedKeys: [#keyPath(ZMAssetClientMessage.hasDownloadedFile)],
                uiContext: managedObjectContext.zm_userInterface!
            )
        }
    }

    private func storeAndDecrypt(data: Data, for message: ZMAssetClientMessage) -> Bool {
        guard
            let genericMessage = message.underlyingMessage,
            let asset = genericMessage.assetData
        else {
            return false
        }

        let keys = (asset.uploaded.otrKey, asset.uploaded.sha256)

        if asset.original.hasRasterImage {
            return validateAndStoreImage(
                asset: asset,
                message: message,
                data: data,
                keys: keys
            )
        } else {
            return validateAndStoreFile(
                asset: asset,
                message: message,
                data: data,
                keys: keys
            )
        }
    }

    private func validateAndStoreImage(
        asset: WireProtos.Asset,
        message: ZMAssetClientMessage,
        data: Data,
        keys: DecryptionKeys
    ) -> Bool {
        precondition(asset.original.hasRasterImage, "Should only be called for assets with image")

        guard data.zmSHA256Digest() == keys.sha256 else {
            zmLog.warn("v3 asset (image) message: \(asset), nonce:\(message.nonce!) digest is not valid, discarding...")
            return false
        }

        managedObjectContext.zm_fileAssetCache.storeEncryptedMediumImage(
            data: data,
            for: message
        )

        return true
    }

    private func validateAndStoreFile(
        asset: WireProtos.Asset,
        message: ZMAssetClientMessage,
        data: Data,
        keys: DecryptionKeys
    ) -> Bool {
        precondition(!asset.original.hasRasterImage, "Should not be called for assets with image")

        guard data.zmSHA256Digest() == keys.sha256 else {
            zmLog.warn("v3 asset (file) message: \(asset), nonce:\(message.nonce!) digest is not valid, discarding...")
            return false
        }

        managedObjectContext.zm_fileAssetCache.storeEncryptedFile(
            data: data,
            for: message
        )

        return true
    }

    // MARK: - ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [assetDownstreamObjectSync]
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest! {
        if let assetClientMessage = object as? ZMAssetClientMessage {
            let taskCreationHandler = ZMTaskCreatedHandler(on: managedObjectContext) { taskIdentifier in
                assetClientMessage.associatedTaskIdentifier = taskIdentifier
            }

            let completionHandler = ZMCompletionHandler(on: managedObjectContext) { response in
                self.handleResponse(response, forMessage: assetClientMessage)
            }

            let progressHandler = ZMTaskProgressHandler(on: managedObjectContext) { progress in
                assetClientMessage.progress = progress
                self.managedObjectContext.enqueueDelayedSave()
            }

            if let asset = assetClientMessage.underlyingMessage?.assetData {
                let token = asset.uploaded.hasAssetToken ? asset.uploaded.assetToken : nil
                let domain = asset.uploaded.assetDomain
                if let request = requestFactory.requestToGetAsset(
                    withKey: asset.uploaded.assetID,
                    token: token,
                    domain: domain,
                    apiVersion: apiVersion
                ) {
                    request.add(taskCreationHandler)
                    request.add(completionHandler)
                    request.add(progressHandler)
                    return request
                }
            }
        }

        fatalError("Cannot generate request for \(String(describing: object))")
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }
}
