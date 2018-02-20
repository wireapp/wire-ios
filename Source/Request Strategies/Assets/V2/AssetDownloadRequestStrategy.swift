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

public struct AssetDownloadRequestStrategyNotification {
    public static let downloadFinishedNotificationName = Notification.Name("AssetDownloadRequestStrategyDownloadFinishedNotificationName")
    public static let downloadStartTimestampKey = "downloadRequestStartTimestamp"
    public static let downloadFailedNotificationName = Notification.Name("AssetDownloadRequestStrategyDownloadFailedNotificationName")
}

@objc public final class AssetDownloadRequestStrategy: AbstractRequestStrategy, ZMDownstreamTranscoder, ZMContextChangeTrackerSource {
    
    fileprivate var assetDownstreamObjectSync: ZMDownstreamObjectSync!
    private var token: Any? = nil
    
    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        configuration = [.allowsRequestsDuringEventProcessing]
        
        registerForCancellationNotification()
        
        let downstreamPredicate = NSPredicate(format: "transferState == %d AND visibleInConversation != nil AND version < 3", ZMFileTransferState.downloading.rawValue)

        let filter = NSPredicate { object, _ in
            guard let message = object as? ZMAssetClientMessage else { return false }
            guard message.fileMessageData != nil else { return false }
            return message.assetId != nil
        }
        
        self.assetDownstreamObjectSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            predicateForObjectsToDownload: downstreamPredicate,
            filter: filter,
            managedObjectContext: managedObjectContext
        )
    }
    
    func registerForCancellationNotification() {
        
        self.token = NotificationInContext.addObserver(name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
                                          context: self.managedObjectContext.notificationContext,
                                          object: nil)
        { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.cancelOngoingRequestForAssetClientMessage(objectID)
        }
    }
    
    func cancelOngoingRequestForAssetClientMessage(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            guard let message = self.managedObjectContext.registeredObject(for: objectID) as? ZMAssetClientMessage else { return }
            guard message.version < 3 else { return }
            guard let identifier = message.associatedTaskIdentifier else { return }
            self.applicationStatus?.requestCancellation.cancelTask(with: identifier)
            message.associatedTaskIdentifier = nil
        }
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return self.assetDownstreamObjectSync.nextRequest()
    }
    
    fileprivate func handleResponse(_ response: ZMTransportResponse, forMessage assetClientMessage: ZMAssetClientMessage) {
        if response.result == .success {
            guard let fileMessageData = assetClientMessage.fileMessageData,
                let asset = assetClientMessage.genericAssetMessage?.assetData,
                let filename = fileMessageData.filename
            else { return }
            guard assetClientMessage.visibleInConversation != nil else {
                // If the assetClientMessage was "deleted" (e.g. due to ephemeral) before the download finished, 
                // we don't want to update the message
                return
            }
            
            // TODO: create request that streams directly to the cache file, otherwise the memory would overflow on big files
            let fileCache = self.managedObjectContext.zm_fileAssetCache
            fileCache.storeAssetData(assetClientMessage.nonce, fileName: filename, encrypted: true, data: response.rawData!)

            let decryptionSuccess = fileCache.decryptFileIfItMatchesDigest(
                assetClientMessage.nonce,
                fileName: filename,
                encryptionKey: asset.uploaded.otrKey,
                sha256Digest: asset.uploaded.sha256
            )
            
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
        let uiManagedObjectContext = self.managedObjectContext.zm_userInterface
        self.managedObjectContext.saveOrRollback() // I have to force this, or message could not have been merged to UI context when I call the next block
        uiManagedObjectContext?.performGroupedBlock({ () -> Void in
            let uiMessage = (try? uiManagedObjectContext!.existingObject(with: messageObjectId)) as? ZMAssetClientMessage
            
            let userInfo: [String: Any] = [AssetDownloadRequestStrategyNotification.downloadStartTimestampKey: response.startOfUploadTimestamp ?? Date()]
            if uiMessage?.transferState == .downloaded {
                NotificationInContext(name: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName,
                                      context: self.managedObjectContext.notificationContext,
                                      object: uiMessage,
                                      userInfo: userInfo).post()
            }
            else {
                NotificationInContext(name: AssetDownloadRequestStrategyNotification.downloadFailedNotificationName,
                                      context: self.managedObjectContext.notificationContext,
                                      object: uiMessage,
                                      userInfo: userInfo).post()
            }
        })
    }
    
    // MARK: - ZMContextChangeTrackerSource
    
    public var contextChangeTrackers: [ZMContextChangeTracker] {
            return [self.assetDownstreamObjectSync]
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


            if let request = ClientMessageRequestFactory().downstreamRequestForEcryptedOriginalFileMessage(assetClientMessage) {
                request.add(taskCreationHandler)
                request.add(completionHandler)
                request.add(progressHandler)
                return request
            }
        }
        
        fatalError("Cannot generate request for \(object)")
    }
    
    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }
    
    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }
}
