//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


import zimages
import ZMTransport


fileprivate let zmLog = ZMSLog(tag: "Asset V3")


@objc public final class AssetV3DownloadRequestStrategy: NSObject, RequestStrategy, ZMDownstreamTranscoder, ZMContextChangeTrackerSource {

    fileprivate var assetDownstreamObjectSync: ZMDownstreamObjectSync!
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate weak var authStatus: ClientRegistrationDelegate?
    fileprivate weak var taskCancellationProvider: ZMRequestCancellation?

    private typealias DecryptionKeys = (otrKey: Data, sha256: Data)

    public init(authStatus: ClientRegistrationDelegate, taskCancellationProvider: ZMRequestCancellation, managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.authStatus = authStatus
        self.taskCancellationProvider = taskCancellationProvider
        super.init()

        zmLog.debug("Asset V3 file download logging set up.")
        registerForCancellationNotification()

        let downstreamPredicate = NSPredicate(format: "transferState == %d AND visibleInConversation != nil AND version == 3", ZMFileTransferState.downloading.rawValue)

        let filter = NSPredicate { object, _ in
            guard let message = object as? ZMAssetClientMessage else { return false }
            guard message.fileMessageData != nil else { return false }
            guard let asset = message.genericAssetMessage?.assetData else { return false }
            return asset.hasUploaded() && asset.uploaded.hasAssetId()
        }

        self.assetDownstreamObjectSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            predicateForObjectsToDownload: downstreamPredicate,
            filter: filter,
            managedObjectContext: managedObjectContext
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func registerForCancellationNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(cancelOngoingRequestForAssetClientMessage), name: NSNotification.Name(rawValue: ZMAssetClientMessageDidCancelFileDownloadNotificationName), object: nil)
    }

    func cancelOngoingRequestForAssetClientMessage(_ note: Notification) {
        guard let objectID = note.object as? NSManagedObjectID else { return }
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let message = self?.managedObjectContext.registeredObject(for: objectID) as? ZMAssetClientMessage else { return }
            guard message.version == 3 else { return }
            guard let identifier = message.associatedTaskIdentifier else { return }
            self?.taskCancellationProvider?.cancelTask(with: identifier)
            message.associatedTaskIdentifier = nil
        }
    }

    public func nextRequest() -> ZMTransportRequest? {
        guard let registration = self.authStatus, registration.clientIsReadyForRequests else {
            return .none
        }

        return self.assetDownstreamObjectSync.nextRequest()
    }

    fileprivate func handleResponse(_ response: ZMTransportResponse, forMessage assetClientMessage: ZMAssetClientMessage) {
        if response.result == .success {
            guard let fileMessageData = assetClientMessage.fileMessageData,
                assetClientMessage.visibleInConversation != nil else { return }

            let decryptionSuccess = storeAndDecrypt(data: response.rawData!, for: assetClientMessage, fileMessageData: fileMessageData)
            if decryptionSuccess {
                assetClientMessage.transferState = .downloaded
            }
            else {
                assetClientMessage.transferState = .failedDownload
            }
        }
        else {
            if assetClientMessage.transferState == .downloading {
                assetClientMessage.transferState = .failedDownload
            }
        }

        let messageObjectId = assetClientMessage.objectID
        let uiMOC = self.managedObjectContext.zm_userInterface!
        uiMOC.performGroupedBlock({ () -> Void in
            let uiMessage = try? uiMOC.existingObject(with: messageObjectId)

            let userInfo = [AssetDownloadRequestStrategyNotification.downloadStartTimestampKey: response.startOfUploadTimestamp]
            if assetClientMessage.transferState == .downloaded {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName), object: uiMessage, userInfo: userInfo)
            }
            else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFailedNotificationName), object: uiMessage, userInfo: userInfo)
            }
        })
    }

    private func storeAndDecrypt(data: Data, for message: ZMAssetClientMessage, fileMessageData: ZMFileMessageData) -> Bool {
        guard let fileMessageData = message.fileMessageData,
            let genericMessage = message.genericAssetMessage,
            let asset = genericMessage.assetData else { return false }

        let keys = (asset.uploaded.otrKey!, asset.uploaded.sha256!)

        if asset.original.hasImage() {
            return storeAndDecryptImage(asset: asset, nonce: message.nonce, data: data, keys: keys)
        } else {
            return storeAndDecryptFile(asset: asset, nonce: message.nonce, data: data, keys: keys, name: fileMessageData.filename)
        }
    }

    private func storeAndDecryptImage(asset: ZMAsset, nonce: UUID, data: Data, keys: DecryptionKeys) -> Bool {
        precondition(asset.original.hasImage(), "Should only be called for assets with image")

        let cache = managedObjectContext.zm_imageAssetCache!
        cache.storeAssetData(nonce, format: .medium, encrypted: true, data: data)
        let success = cache.decryptFileIfItMatchesDigest(nonce, format: .medium, encryptionKey: keys.otrKey, sha256Digest: keys.sha256)
        if !success {
            zmLog.error("Failed to decrypt v3 asset (image) message: \(asset), nonce:\(nonce)")
        }
        return success
    }

    private func storeAndDecryptFile(asset: ZMAsset, nonce: UUID, data: Data, keys: DecryptionKeys, name: String) -> Bool {
        precondition(!asset.original.hasImage(), "Should not be called for assets with image")

        let cache = managedObjectContext.zm_fileAssetCache
        cache.storeAssetData(nonce, fileName: name, encrypted: true, data: data)
        let success = cache.decryptFileIfItMatchesDigest(nonce, fileName: name, encryptionKey: keys.otrKey, sha256Digest: keys.sha256)
        if !success {
            zmLog.error("Failed to decrypt v3 asset (file) message: \(asset), nonce:\(nonce), name: \(name)")
        }
        return success
    }

    // MARK: - ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [assetDownstreamObjectSync]
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest! {
        if let assetClientMessage = object as? ZMAssetClientMessage {

            let taskCreationHandler = ZMTaskCreatedHandler(on: managedObjectContext) { taskIdentifier in
                assetClientMessage.associatedTaskIdentifier = taskIdentifier
            }

            let completionHandler = ZMCompletionHandler(on: self.managedObjectContext) { response in
                self.handleResponse(response, forMessage: assetClientMessage)
            }

            let progressHandler = ZMTaskProgressHandler(on: self.managedObjectContext) { progress in
                assetClientMessage.progress = progress
                self.managedObjectContext.enqueueDelayedSave()
            }

            if let asset = assetClientMessage.genericAssetMessage?.assetData {
                let token = asset.uploaded.hasAssetToken() ? asset.uploaded.assetToken : nil
                if let request = AssetDownloadRequestFactory().requestToGetAsset(withKey: asset.uploaded.assetId, token: token) {
                    request.add(taskCreationHandler)
                    request.add(completionHandler)
                    request.add(progressHandler)
                    return request
                }
            }
        }

        fatalError("Cannot generate request for \(object)")
    }

    public func delete(_ object: ZMManagedObject!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }
}
