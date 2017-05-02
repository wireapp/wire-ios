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


import WireImages
import WireTransport
import WireRequestStrategy


private let zmLog = ZMSLog(tag: "AssetPreviewDownloading")


@objc public final class AssetV3PreviewDownloadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    fileprivate var downstreamSync: ZMDownstreamObjectSyncWithWhitelist!
    
    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        let filter = NSPredicate { object, _ in
            guard let message = object as? ZMAssetClientMessage, nil != message.fileMessageData else { return false }
            guard message.version == 3, message.visibleInConversation != nil else { return false }
            guard nil != message.genericAssetMessage?.previewAssetId else { return false }
            return !message.hasDownloadedImage
        }

        downstreamSync = ZMDownstreamObjectSyncWithWhitelist(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            predicateForObjectsToDownload: filter,
            managedObjectContext: managedObjectContext
        )
        registerForWhitelistingNotification()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func registerForWhitelistingNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didRequestToDownloadImage),
            name: NSNotification.Name(rawValue: ZMAssetClientMessage.ImageDownloadNotificationName),
            object: nil
        )
    }

    func didRequestToDownloadImage(_ note: Notification) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            guard let objectID = note.object as? NSManagedObjectID else { return }
            guard let object = try? self.managedObjectContext.existingObject(with: objectID) else { return }
            guard let message = object as? ZMAssetClientMessage else { return }
            self.downstreamSync.whiteListObject(message)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return downstreamSync.nextRequest()
    }

    fileprivate func handleResponse(_ response: ZMTransportResponse, forMessage assetClientMessage: ZMAssetClientMessage) {
        guard let asset = assetClientMessage.genericAssetMessage?.assetData, response.result == .success else { return }
        guard let remote = asset.preview.remote, assetClientMessage.visibleInConversation != nil else { return }

        let cache = managedObjectContext.zm_imageAssetCache!
        cache.storeAssetData(assetClientMessage.nonce, format: .medium, encrypted: true, data: response.rawData!)

        // Decrypt the preview image file
        let success = cache.decryptFileIfItMatchesDigest(
            assetClientMessage.nonce,
            format: .medium,
            encryptionKey: remote.otrKey,
            sha256Digest: remote.sha256
        )

        if !success {
            zmLog.error("Unable to decrypt preview image for file message: \(assetClientMessage), \(asset)")
        }

        // Notify about the changes
        guard let uiMOC = managedObjectContext.zm_userInterface else { return }
        NotificationDispatcher.notifyNonCoreDataChanges(objectID: assetClientMessage.objectID,
                                                        changedKeys: [ZMAssetClientMessageDownloadedImageKey],
                                                        uiContext: uiMOC)
    }

    // MARK: - ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [downstreamSync]
    }

}

// MARK: - ZMDownstreamTranscoder

extension AssetV3PreviewDownloadRequestStrategy: ZMDownstreamTranscoder {

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest! {
        if let assetClientMessage = object as? ZMAssetClientMessage,
            let asset = assetClientMessage.genericAssetMessage?.assetData,
            let remote = asset.preview.remote,
            assetClientMessage.version == 3 {

            let token = remote.hasAssetToken() ? remote.assetToken : nil
            if let request = AssetDownloadRequestFactory().requestToGetAsset(withKey: remote.assetId, token: token) {
                request.add(ZMCompletionHandler(on: self.managedObjectContext) { response in
                    self.handleResponse(response, forMessage: assetClientMessage)
                })
                return request
            }
        }

        fatal("Cannot generate request to download v3 file preview for \(object)")
    }

    public func delete(_ object: ZMManagedObject!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

}
