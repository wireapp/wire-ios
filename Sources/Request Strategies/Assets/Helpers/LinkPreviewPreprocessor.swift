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
import WireDataModel
import WireUtilities

private let zmLog = ZMSLog(tag: "link previews")

@objcMembers public final class LinkPreviewPreprocessor : NSObject, ZMContextChangeTracker {
        
    /// List of objects currently being processed
    fileprivate var objectsBeingProcessed = Set<ZMClientMessage>()
    fileprivate let linkPreviewDetector: LinkPreviewDetectorType

    let managedObjectContext : NSManagedObjectContext
    
    public init(linkPreviewDetector: LinkPreviewDetectorType, managedObjectContext: NSManagedObjectContext) {
        self.linkPreviewDetector = linkPreviewDetector
        self.managedObjectContext = managedObjectContext
        super.init()
        self.linkPreviewDetector.delegate = self
    }

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        processObjects(objects)
    }
    
    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let predicate = NSPredicate(format: "%K == %d", ZMClientMessageLinkPreviewStateKey, ZMLinkPreviewState.waitingToBeProcessed.rawValue)
        return ZMClientMessage.sortedFetchRequest(with: predicate)
    }
    
    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        processObjects(objects)
    }
    
    func processObjects(_ objects: Set<NSObject>) {
        objects
            .compactMap(linkPreviewsToPreprocess)
            .filter(!objectsBeingProcessed.contains)
            .forEach(processMessage)
    }
    
    func linkPreviewsToPreprocess(_ object: NSObject) -> ZMClientMessage? {
        guard let message = object as? ZMClientMessage else { return nil }
        return message.linkPreviewState == .waitingToBeProcessed ? message : nil
    }
    
    func processMessage(_ message: ZMClientMessage) {
        objectsBeingProcessed.insert(message)
        
        if let messageText = (message as ZMConversationMessage).textMessageData?.messageText {
            zmLog.debug("fetching previews for: \(message.nonce?.uuidString ?? "nil")")
            linkPreviewDetector.downloadLinkPreviews?(inText: messageText) { [weak self] linkPreviews in

                self?.managedObjectContext.performGroupedBlock {
                    zmLog.debug("\(linkPreviews.count) previews for: \(message.nonce?.uuidString ?? "nil")\n\(linkPreviews)")
                    self?.didProcessMessage(message, linkPreviews: linkPreviews)
                }
            }
        } else {
            didProcessMessage(message, linkPreviews: [])
        }
    }
    
    func didProcessMessage(_ message: ZMClientMessage, linkPreviews: [LinkPreview]) {
        objectsBeingProcessed.remove(message)
        
        if let preview = linkPreviews.first, let messageText = message.textMessageData?.messageText, !message.isObfuscated {
            let updatedMessage = ZMGenericMessage.message(text: messageText, linkPreview: preview.protocolBuffer, nonce: message.nonce!, expiresAfter: NSNumber(value: message.deletionTimeout))
            message.add(updatedMessage.data())
            
            if let imageData = preview.imageData.first {
                zmLog.debug("image in linkPreview (need to upload), setting state to .downloaded for: \(message.nonce?.uuidString ?? "nil")")
                managedObjectContext.zm_fileAssetCache.storeAssetData(message, format: .original, encrypted: false, data: imageData)
                message.linkPreviewState = .downloaded
            } else {
                zmLog.debug("no image in preview, setting state to .uploaded for: \(message.nonce?.uuidString ?? "nil")")
                message.linkPreviewState = .uploaded
            }
        } else {
            zmLog.debug("no linkpreview or obfuscated message, setting state to .done for: \(message.nonce?.uuidString ?? "nil")")
            message.linkPreviewState = .done
        }
        
        // The change processor is called as a response to a context save, 
        // which is why we need to enque a save maually here
        managedObjectContext.enqueueDelayedSave()
    }
}

extension LinkPreviewPreprocessor: LinkPreviewDetectorDelegate {
    public func shouldDetectURL(_ url: URL, range: NSRange, text: String) -> Bool {
        // We DONT want to generate link previews for markdown links such as
        // [click me!](www.example.com). So, we get all ranges of markdown links
        // and return false if the url range is equal to one of these
        guard let regex = try? NSRegularExpression(pattern: "\\[.+\\]\\((.+)\\)", options: []) else { return true }
        let wholeRange = NSMakeRange(0, (text as NSString).length)
        return  !regex
            .matches(in: text, options: [], range: wholeRange)
            .map { $0.range(at: 1) }
            .contains { NSEqualRanges($0, range) }
    }
}
