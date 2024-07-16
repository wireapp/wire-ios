//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

/**
 Preprocess the assets before they are uploaded.
 
 - images are downscaled and converted to jpeg if they are too big
 - all assets are encrypted
 
 */
@objcMembers public final class AssetsPreprocessor: NSObject, ZMContextChangeTracker {

    /// Group to track preprocessing operations
    fileprivate let processingGroup: ZMSDispatchGroup

    /// List of objects currently being processed
    fileprivate var objectsBeingProcessed = Set<ZMAssetClientMessage>()
    fileprivate let imageProcessingQueue: OperationQueue
    fileprivate var imageAssetPreprocessor: ZMAssetsPreprocessor?

    /// Managed object context. Is is assumed that all methods of this class
    /// are called from the thread of this managed object context
    let managedObjectContext: NSManagedObjectContext

    /// Creates a file processor
    /// - note: All methods of this object should be called from the thread associated with the passed managedObjectContext
    public init(managedObjectContext: NSManagedObjectContext) {
        self.processingGroup = ZMSDispatchGroup(label: "Asset Preprocessing")
        self.managedObjectContext = managedObjectContext
        self.imageProcessingQueue = ZMImagePreprocessor.createSuitableImagePreprocessingQueue()

        super.init()

        self.imageAssetPreprocessor = ZMAssetsPreprocessor(delegate: self)

    }

    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        WireLogger.assets.debug("objectsDidChange")
        processObjects(object)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let predicate = NSPredicate(format: "version >= 3 && %K == NO", DeliveredKey)
        return ZMAssetClientMessage.sortedFetchRequest(with: predicate)
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        WireLogger.assets.debug("addTrackedObjects")
        processObjects(objects)
    }

    private func processObjects(_ objects: Set<NSManagedObject>) {
        objects
            .compactMap(needsPreprocessing)
            .filter(!objectsBeingProcessed.contains)
            .forEach(startProcessing)
    }

    /// Starts processing the asset client message
    fileprivate func startProcessing(_ message: ZMAssetClientMessage) {
        objectsBeingProcessed.insert(message)

        _ = managedObjectContext.enterAllGroups()

        // We only want to start processing originals.
        for asset in message.assets where asset.hasOriginal {
            if asset.needsPreprocessing, let imageOperations = imageAssetPreprocessor?.operations(forPreprocessingImageOwner: AssetImageOwnerAdapter(asset: asset)) {
                processingGroup.enter()
                WireLogger.assets.debug("asset image op", attributes: [LogAttributesKey.nonce.rawValue: message.nonce?.safeForLoggingDescription ?? "<nil>"])
                imageProcessingQueue.addOperations(imageOperations, waitUntilFinished: false)
            } else {
                WireLogger.assets.debug("asset encrypt file", attributes: [LogAttributesKey.nonce.rawValue: message.nonce?.safeForLoggingDescription ?? "<nil>"])
                asset.encrypt()
            }
        }

        notifyWhenProcessingIsComplete(message)
    }

    /// Removes the message from the list of messages being processed when the processing is completed
    fileprivate func notifyWhenProcessingIsComplete(_ message: ZMAssetClientMessage) {
        processingGroup.notify(on: .global()) { [weak self] in
            self?.managedObjectContext.performGroupedBlock {
                self?.objectsBeingProcessed.remove(message)
                WireLogger.assets.debug("notifyWhenProcessingIsComplete", attributes: [LogAttributesKey.nonce.rawValue: message.nonce?.safeForLoggingDescription ?? "<nil>"])
//                message.updateTransferState(.uploaded, synchronize: true)
                let assetClientMessageSet: Set<AnyHashable> = [#keyPath(ZMAssetClientMessage.transferState)]
                message.setLocallyModifiedKeys(assetClientMessageSet) // TODO jacob hacky
                message.managedObjectContext?.saveOrRollback()
                self?.managedObjectContext.leaveAllGroups(self?.managedObjectContext.allGroups())
            }
        }
    }

    /// Returns the object as a ZMAssetClientMessage if it is asset that needs preprocessing
    private func needsPreprocessing(_ object: NSManagedObject) -> ZMAssetClientMessage? {
        guard let message = object as? ZMAssetClientMessage else { return nil }

        return message.processingState == .preprocessing ? message : nil
    }
}

extension AssetsPreprocessor: ZMAssetsPreprocessorDelegate {

    public func completedDownsampleOperation(_ operation: ZMImageDownsampleOperationProtocol, imageOwner: ZMImageOwner) {
        guard let assetImageOwnerAdapter = imageOwner as? AssetImageOwnerAdapter else { return }

        managedObjectContext.performGroupedBlock {
            assetImageOwnerAdapter.asset.updateWithPreprocessedData(operation.downsampleImageData, imageProperties: operation.properties)
            WireLogger.assets.debug("asset image encrypt")
            assetImageOwnerAdapter.asset.encrypt()
        }
    }

    public func failedPreprocessingImageOwner(_ imageOwner: ZMImageOwner) {
        // TODO jacob is never called, remove
    }

    public func didCompleteProcessingImageOwner(_ imageOwner: ZMImageOwner) {
        // TODO jacob is never called, remove
    }

    public func preprocessingCompleteOperation(for imageOwner: ZMImageOwner) -> Operation? {
        return BlockOperation { [weak self] in
            WireLogger.assets.debug("preprocessingCompleteOperation")
            self?.processingGroup.leave()
        }
    }

}

/// Adapter which implements the ZMImageOwner protcol because it requires an NSObject
class AssetImageOwnerAdapter: NSObject, ZMImageOwner {

    let asset: AssetType

    init(asset: AssetType) {
        self.asset = asset

        super.init()
    }

    func requiredImageFormats() -> NSOrderedSet {
        return NSOrderedSet(array: [ZMImageFormat.medium.rawValue])
    }

    func originalImageData() -> Data? {
        return asset.original
    }

}
