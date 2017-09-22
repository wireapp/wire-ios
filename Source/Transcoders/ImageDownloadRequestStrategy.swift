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

import Foundation
import WireRequestStrategy

public final class ImageDownloadRequestStrategy : AbstractRequestStrategy {
    
    fileprivate var downstreamSync : ZMDownstreamObjectSyncWithWhitelist!
    fileprivate let requestFactory : ClientMessageRequestFactory = ClientMessageRequestFactory()
    private var token: Any? = nil

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        let downloadPredicate = NSPredicate { (object, _) -> Bool in
            guard let message = object as? ZMAssetClientMessage else { return false }
            guard message.version < 3 else { return false }
            let missingMediumImage = message.imageMessageData != nil && !message.hasDownloadedImage && message.assetId != nil
            let missingVideoThumbnail = message.fileMessageData != nil && !message.hasDownloadedImage && message.fileMessageData?.thumbnailAssetID != nil
            return missingMediumImage || missingVideoThumbnail
        }
        
        downstreamSync = ZMDownstreamObjectSyncWithWhitelist(transcoder: self,
                                                             entityName: ZMAssetClientMessage.entityName(),
                                                             predicateForObjectsToDownload: downloadPredicate,
                                                             managedObjectContext: managedObjectContext)

        registerForWhitelistingNotification()
    }
    
    func registerForWhitelistingNotification() {
        self.token = NotificationInContext.addObserver(name: ZMAssetClientMessage.imageDownloadNotificationName,
                                          context: self.managedObjectContext.notificationContext,
                                          object: nil)
        { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.didRequestToDownloadImage(objectID)
        }
    }
    
    func didRequestToDownloadImage(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            guard let object = try? self.managedObjectContext.existingObject(with: objectID) else { return }
            guard let message = object as? ZMAssetClientMessage else { return }
            self.downstreamSync.whiteListObject(message)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return downstreamSync.nextRequest()
    }

}

extension ImageDownloadRequestStrategy : ZMDownstreamTranscoder {
    
    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest! {
        guard let message = object as? ZMAssetClientMessage, let conversation = message.conversation else { return nil }
        
        if let existingData = managedObjectContext.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false) {
            updateMediumImage(forMessage: message, imageData: existingData)
            managedObjectContext.enqueueDelayedSave()
            return nil
        } else {
            if message.imageMessageData != nil {
                guard let assetId = message.assetId?.transportString() else { return nil }
                return requestFactory.requestToGetAsset(assetId, inConversation: conversation.remoteIdentifier!, isEncrypted: message.isEncrypted)
            } else if (message.fileMessageData != nil) {
                guard let assetId = message.fileMessageData?.thumbnailAssetID else { return nil }
                return requestFactory.requestToGetAsset(assetId, inConversation: conversation.remoteIdentifier!, isEncrypted: message.isEncrypted)
            }
        }
        
        return nil
    }
    
    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let message = object as? ZMAssetClientMessage else { return }
        updateMediumImage(forMessage: message, imageData: response.rawData!)
    }
    
    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let message = object as? ZMAssetClientMessage else { return }
        message.managedObjectContext?.delete(message)
    }
    
    fileprivate func updateMediumImage(forMessage message: ZMAssetClientMessage, imageData: Data) {
        _ = message.imageAssetStorage.updateMessage(imageData: imageData, for: .medium)
        
        guard let uiMOC = managedObjectContext.zm_userInterface else { return }
        NotificationDispatcher.notifyNonCoreDataChanges(objectID: message.objectID,
                                                        changedKeys: [#keyPath(ZMAssetClientMessage.hasDownloadedImage)],
                                                        uiContext: uiMOC)
    }
    
}
