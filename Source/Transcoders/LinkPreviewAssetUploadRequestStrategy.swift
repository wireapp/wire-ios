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
import WireLinkPreview
import WireRequestStrategy

@objc public final class LinkPreviewDetectorHelper : NSObject {
    fileprivate static var _test_debug_linkPreviewDetector : LinkPreviewDetectorType? = nil
    
    @objc public class func test_debug_linkPreviewDetector() -> LinkPreviewDetectorType?
    {
        return _test_debug_linkPreviewDetector
    }
    
    @objc public class func setTest_debug_linkPreviewDetector(_ detectorType: LinkPreviewDetectorType?)
    {
        _test_debug_linkPreviewDetector = detectorType
    }
    
    @objc public class func tearDown()
    {
        _test_debug_linkPreviewDetector = nil
    }
    
}

private let zmLog = ZMSLog(tag: "link previews")

extension ZMImagePreprocessingTracker {
    static func createPreviewImagePreprocessingTracker(managedObjectContext: NSManagedObjectContext) -> ZMImagePreprocessingTracker! {
        let imageFetchPredicate = NSPredicate(format: "%K == %d",ZMClientMessageLinkPreviewStateKey, ZMLinkPreviewState.downloaded.rawValue)
        let needsProccessing = NSPredicate { object, _ in
            guard let message = object as? ZMClientMessage else { return false }
            return nil != managedObjectContext.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false)
        }
        
        let previewImagePreprocessor = ZMImagePreprocessingTracker(
            managedObjectContext:       managedObjectContext,
            imageProcessingQueue:       OperationQueue(),
            fetch:             imageFetchPredicate,
            needsProcessingPredicate:   needsProccessing,
            entityClass:                ZMClientMessage.self
        )
        return previewImagePreprocessor
    }
}


public final class LinkPreviewAssetUploadRequestStrategy : AbstractRequestStrategy, ZMContextChangeTrackerSource {
    
    let requestFactory = AssetRequestFactory()
    
    /// Processors
    fileprivate let linkPreviewPreprocessor : LinkPreviewPreprocessor
    fileprivate let previewImagePreprocessor : ZMImagePreprocessingTracker
    
    /// Upstream sync
    fileprivate var assetUpstreamSync : ZMUpstreamModifiedObjectSync!
    
    @available(*, unavailable)
    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        fatalError()
    }
    
    public init(managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus, linkPreviewPreprocessor: LinkPreviewPreprocessor?, previewImagePreprocessor: ZMImagePreprocessingTracker?) {
        if nil == LinkPreviewDetectorHelper.test_debug_linkPreviewDetector() {
            LinkPreviewDetectorHelper.setTest_debug_linkPreviewDetector(LinkPreviewDetector(resultsQueue: OperationQueue.current!))
        }
        self.linkPreviewPreprocessor = linkPreviewPreprocessor ?? LinkPreviewPreprocessor(linkPreviewDetector: LinkPreviewDetectorHelper.test_debug_linkPreviewDetector()!, managedObjectContext: managedObjectContext)
        self.previewImagePreprocessor = previewImagePreprocessor ?? ZMImagePreprocessingTracker.createPreviewImagePreprocessingTracker(managedObjectContext: managedObjectContext)
        
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.assetUpstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMClientMessage.entityName(),
            update: predicateForAssetUpload,
            filter: filterForAssetUpload,
            keysToSync: [ZMClientMessageLinkPreviewStateKey],
            managedObjectContext: managedObjectContext)
    }

    var predicateForAssetUpload : NSPredicate {
        return NSPredicate(format: "%K == %d", ZMClientMessageLinkPreviewStateKey, ZMLinkPreviewState.processed.rawValue)
    }
    
    var filterForAssetUpload: NSPredicate {
        return NSPredicate { [unowned self] object, _ in
            guard let message = object as? ZMClientMessage else { return false }
            return nil != self.managedObjectContext.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true)
        }
    }
    
    public var contextChangeTrackers : [ZMContextChangeTracker] {
        return [self.linkPreviewPreprocessor, self.previewImagePreprocessor, self.assetUpstreamSync]
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return self.assetUpstreamSync.nextRequest()
    }
}

extension LinkPreviewAssetUploadRequestStrategy : ZMUpstreamTranscoder {
    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMClientMessage else { return nil }
        guard keys.contains(ZMClientMessageLinkPreviewStateKey) else { return nil }

        guard let imageData = managedObjectContext.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true) else { return nil }
        return ZMUpstreamRequest(keys: [ZMClientMessageLinkPreviewStateKey], transportRequest: requestFactory.upstreamRequestForAsset(withData: imageData))
    }
    
    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        return nil
    }
    
    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }
    
    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }
    
    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable: Any]?, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let message = managedObject as? ZMClientMessage else { return false }
        guard keysToParse.contains(ZMClientMessageLinkPreviewStateKey) else { return false }
        guard let payload = response.payload?.asDictionary(), let assetKey = payload["key"] as? String else { fatal("No asset ID present in payload: \(String(describing: response.payload))") }
        
        if let linkPreview = message.genericMessage?.linkPreviews.first, !message.isObfuscated {
            let updatedPreview = linkPreview.update(withAssetKey: assetKey, assetToken: payload["token"] as? String)
            let genericMessage = ZMGenericMessage.message(text: (message.textMessageData?.messageText)!, linkPreview: updatedPreview, nonce: message.nonce.transportString(), expiresAfter: NSNumber(value: message.deletionTimeout))
            message.add(genericMessage.data())
            zmLog.debug("Uploaded image for message with linkPreview: \(linkPreview), genericMessage: \(String(describing: message.genericMessage))")
            message.linkPreviewState = .uploaded
            return true
        } else {
            zmLog.warn("Uploaded image but message does not have a link preview: \(String(describing: message.genericMessage))")
            message.linkPreviewState = .done
        }

        return false
    }
    
    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // nop
    }
    
}
