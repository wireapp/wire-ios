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


private let zmLog = ZMSLog(tag: "AssetPreviewDownloading")


@objc public final class AssetV3PreviewDownloadRequestStrategy: NSObject, RequestStrategy, ZMContextChangeTrackerSource {

    fileprivate var downstreamSync: ZMDownstreamObjectSync!
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate weak var authStatus: ClientRegistrationDelegate?

    public init(authStatus: ClientRegistrationDelegate, managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.authStatus = authStatus
        super.init()

        let downstreamPredicate = NSPredicate(
            format: "transferState == %d AND visibleInConversation != nil AND version == 3",
            ZMFileTransferState.downloading.rawValue
        )

        let filter = NSPredicate { object, _ in
            guard let message = object as? ZMAssetClientMessage, message.fileMessageData != nil else { return false }
            guard nil != message.genericAssetMessage?.previewAssetId else { return false }
            return !message.hasDownloadedImage
        }

        downstreamSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            predicateForObjectsToDownload: downstreamPredicate,
            filter: filter,
            managedObjectContext: managedObjectContext
        )
    }

    public func nextRequest() -> ZMTransportRequest? {
        guard let status = authStatus, status.clientIsReadyForRequests else { return nil }
        return downstreamSync.nextRequest()
    }

    fileprivate func handleResponse(_ response: ZMTransportResponse, forMessage assetClientMessage: ZMAssetClientMessage) {
        guard let asset = assetClientMessage.genericAssetMessage?.assetData, response.result == .success else { return }
        guard let remote = asset.preview.remote, assetClientMessage.visibleInConversation != nil else { return }

        let cache = managedObjectContext.zm_fileAssetCache
        cache.storeAssetData(assetClientMessage.nonce, fileName: remote.assetId, encrypted: true, data: response.rawData!)

        // Decrypt the preview image file
        let success = cache.decryptFileIfItMatchesDigest(
            assetClientMessage.nonce,
            fileName: remote.assetId,
            encryptionKey: remote.otrKey,
            sha256Digest: remote.sha256
        )

        if !success {
            zmLog.error("Unable to decrypt preview image for file message: \(assetClientMessage), \(asset)")
        }

        // Notify about the changes
        let uiMOC = managedObjectContext.zm_userInterface

        uiMOC?.performGroupedBlock {
            guard let message = try? uiMOC?.existingObject(with: assetClientMessage.objectID) else { return }
            uiMOC?.globalManagedObjectContextObserver.notifyNonCoreDataChangeInManagedObject(message!)
        }
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
