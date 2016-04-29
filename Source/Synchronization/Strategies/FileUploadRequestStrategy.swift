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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation


private let reponseHeaderAssetIdKey = "Location"

@objc public class FileUploadRequestStrategyNotification: NSObject {
    public static let uploadFinishedNotificationName = "FileUploadRequestStrategyUploadFinishedNotificationName"
    public static let requestStartTimestampKey = "requestStartTimestamp"
    public static let uploadFailedNotificationName = "FileUploadRequestStrategyUploadFailedNotificationName"
}


@objc public class FileUploadRequestStrategy : ZMObjectSyncStrategy, RequestStrategy, ZMUpstreamTranscoder, ZMContextChangeTrackerSource {
    
    /// Auth status to know whether we can make requests
    private let authenticationStatus : AuthenticationStatusProvider
    
    /// Client status to know whether we can make requests and to delete client
    private var clientRegistrationStatus : ZMClientClientRegistrationStatusProvider
    
    /// Upstream sync
    private var fullFileUpstreamSync : ZMUpstreamModifiedObjectSync!
    
    /// Preprocessor
    private var filePreprocessor : FilePreprocessor
    
    private var requestFactory : ClientMessageRequestFactory
    
    // task cancellation provider
    private weak var taskCancellationProvider: ZMRequestCancellation?
    
    
    public init(authenticationStatus: AuthenticationStatusProvider,
        clientRegistrationStatus : ZMClientClientRegistrationStatusProvider,
        managedObjectContext: NSManagedObjectContext,
        taskCancellationProvider: ZMRequestCancellation)
    {
        self.filePreprocessor = FilePreprocessor(managedObjectContext: managedObjectContext)
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.requestFactory = ClientMessageRequestFactory()
        self.taskCancellationProvider = taskCancellationProvider
        super.init(managedObjectContext: managedObjectContext)
        
        let keys = [
            ZMAssetClientMessage_NeedsToUploadMediumKey,
            ZMAssetClientMessage_NeedsToUploadPreviewKey,
            ZMAssetClientMessage_NeedsToUploadNotUploadedKey
        ]
        
        self.fullFileUpstreamSync = ZMUpstreamModifiedObjectSync(transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            updatePredicate: ZMAssetClientMessage.predicateForFileToUpload,
            filter: ZMAssetClientMessage.filterForFileToUpload,
            keysToSync: keys,
            managedObjectContext: managedObjectContext)
    }
    
    public var contextChangeTrackers : [ZMContextChangeTracker] {
        return [self.fullFileUpstreamSync, self.filePreprocessor]
    }
    
    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }
    
    public func dependentObjectNeedingUpdateBeforeProcessingObject(dependant: ZMManagedObject) -> ZMManagedObject? {
        guard let message = dependant as? ZMAssetClientMessage else { return nil }
        let dependency = message.dependendObjectNeedingUpdateBeforeProcessing()
        return dependency
    }
    
    public func requestForUpdatingObject(managedObject: ZMManagedObject, forKeys keys: Set<NSObject>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMAssetClientMessage else { return nil }
        if keys.contains(ZMAssetClientMessage_NeedsToUploadNotUploadedKey) {
            cancelOutstandingUploadRequests(forMessage: message)
            return ZMUpstreamRequest(
                keys: Set(arrayLiteral: ZMAssetClientMessage_NeedsToUploadNotUploadedKey),
                transportRequest: requestToUploadNotUploaded(message)
            )
        }
        if keys.contains(ZMAssetClientMessage_NeedsToUploadMediumKey) {
            return ZMUpstreamRequest(
                keys: Set(arrayLiteral: ZMAssetClientMessage_NeedsToUploadMediumKey),
                transportRequest: self.requestToUploadFull(message)
            )
        }
        if keys.contains(ZMAssetClientMessage_NeedsToUploadPreviewKey) {
            return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMAssetClientMessage_NeedsToUploadPreviewKey),
                transportRequest: self.requestToUploadOriginal(message))
        }
        return nil
    }
    
    public func requestForInsertingObject(managedObject: ZMManagedObject,
        forKeys keys: Set<NSObject>?) -> ZMUpstreamRequest?
    {
        return nil
    }
    
    public func updateInsertedObject(managedObject: ZMManagedObject,request upstreamRequest: ZMUpstreamRequest,response: ZMTransportResponse)
    {
        guard let message = managedObject as? ZMAssetClientMessage else { return }
        message.parseUploadResponse(response, clientDeletionDelegate: self.clientRegistrationStatus)
    }
    
    public func updateUpdatedObject(managedObject: ZMManagedObject,
        requestUserInfo: [NSObject : AnyObject]?,
        response: ZMTransportResponse,
        keysToParse: Set<NSObject>) -> Bool
    {
        guard let message = managedObject as? ZMAssetClientMessage else { return false	 }
        message.parseUploadResponse(response, clientDeletionDelegate: self.clientRegistrationStatus)
        
        if keysToParse.contains(ZMAssetClientMessage_NeedsToUploadPreviewKey) {
            message.setNeedsToUploadData(.FileData, needsToUpload: true)
            message.setNeedsToUploadData(.Placeholder, needsToUpload: false)
        }
        if keysToParse.contains(ZMAssetClientMessage_NeedsToUploadMediumKey) {
            message.transferState = .Downloaded
            message.delivered = true
            let assetIDTransportString = response.headers?[reponseHeaderAssetIdKey] as? String
            if let assetID = assetIDTransportString.flatMap(NSUUID.uuidWithTransportString) {
                message.assetId = assetID
            }
            self.deleteRequestData(forMessage: message, includingEncryptedAssetData: true)
            
            let messageObjectId = message.objectID
            self.managedObjectContext.zm_userInterfaceContext.performGroupedBlock({ () -> Void in
                let uiMessage = try? self.managedObjectContext.zm_userInterfaceContext.existingObjectWithID(messageObjectId)
                
                let userInfo = [FileUploadRequestStrategyNotification.requestStartTimestampKey: response.startOfUploadTimestamp ?? NSDate()]
                
                NSNotificationCenter.defaultCenter().postNotificationName(FileUploadRequestStrategyNotification.uploadFinishedNotificationName, object: uiMessage, userInfo: userInfo)
            })
        }
        
        return false
    }
    
    public func objectToRefetchForFailedUpdateOfObject(managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }
    
    public func shouldRetryToSyncAfterFailedToUpdateObject(managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse,
        keysToParse keys: Set<NSObject>)-> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        let failedBecauseOfMissing = message.parseUploadResponse(response, clientDeletionDelegate: self.clientRegistrationStatus)
        if !failedBecauseOfMissing {
            failMessageUpload(message, keys: keys, request: upstreamRequest.transportRequest)
        }
        return failedBecauseOfMissing
    }
    
    /// marks the upload as failed
    private func failMessageUpload(message: ZMAssetClientMessage, keys: Set<NSObject>, request: ZMTransportRequest?) {
        
        if message.transferState != .CancelledUpload {
            message.transferState = .FailedUpload
            message.expire()
        }
        
        if keys.contains(ZMAssetClientMessage_NeedsToUploadPreviewKey) {
            message.setNeedsToUploadData(.Placeholder, needsToUpload: false)
            self.deleteRequestData(forMessage: message, includingEncryptedAssetData: true)
        }
        
        if keys.contains(ZMAssetClientMessage_NeedsToUploadMediumKey) {
            message.didFailToUploadFileData()
            self.deleteRequestData(forMessage: message, includingEncryptedAssetData: false)
        }
        
        let messageObjectId = message.objectID
        self.managedObjectContext.zm_userInterfaceContext.performGroupedBlock({ () -> Void in
            let uiMessage = try? self.managedObjectContext.zm_userInterfaceContext.existingObjectWithID(messageObjectId)
            
            let userInfo = [FileUploadRequestStrategyNotification.requestStartTimestampKey: request?.startOfUploadTimestamp != nil ?? NSDate()]
            
            NSNotificationCenter.defaultCenter().postNotificationName(FileUploadRequestStrategyNotification.uploadFailedNotificationName, object: uiMessage, userInfo: userInfo)
        })
    }
    
    func nextRequest() -> ZMTransportRequest? {
        guard self.authenticationStatus.currentPhase == .Authenticated else { return nil }
        guard self.clientRegistrationStatus.currentClientReadyToUse else  { return nil }
        return self.fullFileUpstreamSync.nextRequest()
    }
    
    /// Returns a request to upload original
    private func requestToUploadOriginal(message: ZMAssetClientMessage) -> ZMTransportRequest? {
        let conversationId = message.conversation.remoteIdentifier
        let request = requestFactory.upstreamRequestForEncryptedFileMessage(.Placeholder, message: message, forConversationWithId: conversationId)
        
        request?.addTaskCreatedHandler(ZMTaskCreatedHandler(onGroupQueue: managedObjectContext) { _, taskIdentifier in
            message.associatedTaskIdentifier = taskIdentifier
        })
        
        request?.addCompletionHandler(ZMCompletionHandler(onGroupQueue: managedObjectContext) { response in
            message.associatedTaskIdentifier = nil
            
            if response.result == .Expired || response.result == .TemporaryError || response.result == .TryAgainLater {
                self.failMessageUpload(message, keys: Set(arrayLiteral: ZMAssetClientMessage_NeedsToUploadMediumKey), request: request)
            }
        })
        return request
    }
    
    /// Returns a request to upload full file
    private func requestToUploadFull(message: ZMAssetClientMessage) -> ZMTransportRequest? {
        let conversationId = message.conversation.remoteIdentifier
        let request = requestFactory.upstreamRequestForEncryptedFileMessage(.FileData, message: message, forConversationWithId: conversationId)
        
        request?.addTaskCreatedHandler(ZMTaskCreatedHandler(onGroupQueue: managedObjectContext) { _, taskIdentifier in
          message.associatedTaskIdentifier = taskIdentifier
        })
        
        request?.addCompletionHandler(ZMCompletionHandler(onGroupQueue: managedObjectContext) { response in
            message.associatedTaskIdentifier = nil
            
            if response.result == .Expired || response.result == .TemporaryError || response.result == .TryAgainLater {
                self.failMessageUpload(message, keys: Set(arrayLiteral: ZMAssetClientMessage_NeedsToUploadMediumKey), request: request)
            }
        })
        request?.addProgressHandler(ZMTaskProgressHandler(onGroupQueue: self.managedObjectContext) { progress in
            message.progress = progress
            self.managedObjectContext.enqueueDelayedSave()
        })
        return request
    }
    
    /// Returns a request to upload full file
    private func requestToUploadNotUploaded(message: ZMAssetClientMessage) -> ZMTransportRequest? {
        let conversationId = message.conversation.remoteIdentifier
        let request = requestFactory.upstreamRequestForEncryptedFileMessage(.Placeholder, message: message, forConversationWithId: conversationId)
        return request
    }
    
    private func deleteRequestData(forMessage message: ZMAssetClientMessage, includingEncryptedAssetData: Bool) {
        // delete request data
        message.managedObjectContext?.zm_fileAssetCache.deleteRequestData(message.nonce)
        
        // delete asset data
        if includingEncryptedAssetData {
            message.managedObjectContext?.zm_fileAssetCache.deleteAssetData(message.nonce, fileName: message.filename!, encrypted: true)
        }
    }
    
    private func cancelOutstandingUploadRequests(forMessage message: ZMAssetClientMessage) {
        message.setNeedsToUploadData(.FileData, needsToUpload: false)
        message.setNeedsToUploadData(.Placeholder, needsToUpload: false)
        guard let identifier = message.associatedTaskIdentifier else { return }
        self.taskCancellationProvider?.cancelTaskWithIdentifier(identifier)
    }
}

extension ZMAssetClientMessage {
    
    static var predicateForFileToUpload : NSPredicate {
        
        let notUploadedPredicate = NSPredicate(format: "%K == %d || %K == %d",
            ZMAssetClientMessageTransferStateKey,
            ZMFileTransferState.FailedUpload.rawValue,
            ZMAssetClientMessageTransferStateKey,
            ZMFileTransferState.CancelledUpload.rawValue
        )
        
        let needsUploadPredicate = NSPredicate(format: "(%K == YES || %K == YES) && %K == %d",
            ZMAssetClientMessage_NeedsToUploadMediumKey,
            ZMAssetClientMessage_NeedsToUploadPreviewKey,
            ZMAssetClientMessageTransferStateKey, ZMFileTransferState.Uploading.rawValue
        )
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: [needsUploadPredicate, notUploadedPredicate])
    }
    
    static var filterForFileToUpload : NSPredicate {
        return NSPredicate(format: "isReadyToUploadFile == YES")
    }
    
    var isReadyToUploadFile : Bool {
        return [.Uploading, .FailedUpload, .CancelledUpload].contains(transferState)
            && self.imageMessageData == nil
            && (self.needsToUploadMedium == true || self.needsToUploadPreview == true)
            && self.genericAssetMessage.asset.uploaded.otrKey.length > 0
    }
}
