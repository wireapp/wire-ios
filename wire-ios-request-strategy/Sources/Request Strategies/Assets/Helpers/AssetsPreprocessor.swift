//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

/// Preprocess the assets before they are uploaded.
///
/// - images are downscaled and converted to jpeg if they are too big
/// - all assets are encrypted
///
@objcMembers
public final class AssetsPreprocessor: NSObject, ZMContextChangeTracker, TearDownCapable {

    /// Group to track preprocessing operations
    fileprivate let processingGroup: ZMSDispatchGroup

    /// List of objects currently being processed
    fileprivate var objectsBeingProcessed = Set<ZMAssetClientMessage>()
    let imageProcessingQueue: OperationQueue
    fileprivate var imageAssetPreprocessor: ZMAssetsPreprocessor?
    private var isTornDown = false

    /// Managed object context. Is is assumed that all methods of this class
    /// are called from the thread of this managed object context
    let managedObjectContext: NSManagedObjectContext

    /// Creates a file processor
    /// - note: All methods of this object should be called from the thread associated with the passed
    /// managedObjectContext
    public init(managedObjectContext: NSManagedObjectContext) {
        self.processingGroup = ZMSDispatchGroup(label: "Asset Preprocessing")
        self.managedObjectContext = managedObjectContext
        self.imageProcessingQueue = ZMImagePreprocessor.createSuitableImagePreprocessingQueue()

        super.init()

        self.imageAssetPreprocessor = ZMAssetsPreprocessor(delegate: self)

    }

    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        processObjects(object)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let predicate = NSPredicate(format: "version >= 3 && %K == NO", DeliveredKey)
        return ZMAssetClientMessage.sortedFetchRequest(with: predicate)
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        processObjects(objects)
    }

    public func tearDown() {
        managedObjectContext.performAndWait {
            isTornDown = true
            objectsBeingProcessed.removeAll()
        }
        // Let queued completion operations finish so their processing-group entries are balanced.
        // Downsample callbacks below will ignore their results after teardown.
    }

    private func processObjects(_ objects: Set<NSManagedObject>) {
        guard !isTornDown, managedObjectContext.zm_isValidContext else { return }
        objects
            .compactMap(needsPreprocessing)
            .filter(!objectsBeingProcessed.contains)
            .forEach(startProcessing)
    }

    /// Starts processing the asset client message
    fileprivate func startProcessing(_ message: ZMAssetClientMessage) {
        objectsBeingProcessed.insert(message)

        let groups = managedObjectContext.enterAllGroups()

        // We only want to start processing originals.
        for asset in message.assets where asset.hasOriginal {
            if message.outboxState != .notEnrolled, asset.isUploaded || asset.hasEncrypted { continue }
            if asset.needsPreprocessing,
               let imageOperations = imageAssetPreprocessor?
               .operations(forPreprocessingImageOwner: AssetImageOwnerAdapter(asset: asset)) {
                processingGroup.enter()
                imageProcessingQueue.addOperations(imageOperations, waitUntilFinished: false)
            } else {
                asset.encrypt()
            }
        }

        notifyWhenProcessingIsComplete(message, groups: groups)
    }

    /// Removes the message from the list of messages being processed when the processing is completed
    fileprivate func notifyWhenProcessingIsComplete(_ message: ZMAssetClientMessage, groups: [ZMSDispatchGroup]) {
        let context = managedObjectContext
        processingGroup.notify(on: .global()) { [weak self] in
            context.performGroupedBlock { [weak self] in
                // Teardown can replace the context's group registry or release this preprocessor.
                // Balance the exact groups entered for this work even when its result is ignored.
                defer { groups.forEach { $0.leave() } }
                guard let self, !self.isTornDown, context.zm_isValidContext else { return }
                self.objectsBeingProcessed.remove(message)
                let legacy = message.outboxState == .notEnrolled
                if legacy || (!message.isDeleted && !message.hasBeenDeleted && !message.isExpired
                    && message.outboxState == .queued && message.transferState == .uploading) {
                    if !legacy, message.assets.contains(where: { !$0.isUploaded && !$0.hasEncrypted }) {
                        try? message.failQueuedOutboxOperation()
                        message.expire(withReason: .other)
                    } else {
                        let assetClientMessageSet: Set<AnyHashable> = [#keyPath(ZMAssetClientMessage.transferState)]
                        message.setLocallyModifiedKeys(assetClientMessageSet)
                    }
                    if legacy {
                        message.managedObjectContext?.saveOrRollback()
                    } else if let context = message.managedObjectContext {
                        do {
                            try context.save()
                            _ = message.recoverOutboxAssetPreparation()
                        } catch {
                            context.rollback()
                        }
                    }
                }
            }
        }
    }

    /// Returns the object as a ZMAssetClientMessage if it is asset that needs preprocessing
    private func needsPreprocessing(_ object: NSManagedObject) -> ZMAssetClientMessage? {
        guard let message = object as? ZMAssetClientMessage else { return nil }
        if message.outboxState != .notEnrolled {
            guard managedObjectContext.canProcessOfflinePendingMessages,
                  !message.isDeleted, !message.hasBeenDeleted, !message.isExpired,
                  message.outboxState == .queued, message.transferState == .uploading else { return nil }
        }

        return message.processingState == .preprocessing ? message : nil
    }
}

extension AssetsPreprocessor: ZMAssetsPreprocessorDelegate {

    public func completedDownsampleOperation(
        _ operation: ZMImageDownsampleOperationProtocol,
        imageOwner: ZMImageOwner
    ) {
        guard let assetImageOwnerAdapter = imageOwner as? AssetImageOwnerAdapter else { return }

        managedObjectContext.performGroupedBlock {
            guard !self.isTornDown, self.managedObjectContext.zm_isValidContext else { return }
            assetImageOwnerAdapter.asset.updateWithPreprocessedData(
                operation.downsampleImageData,
                imageProperties: operation.properties
            )
            assetImageOwnerAdapter.asset.encrypt()
        }
    }

    public func failedPreprocessingImageOwner(_ imageOwner: ZMImageOwner) {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: jacob is never called, remove
    }

    public func didCompleteProcessingImageOwner(_ imageOwner: ZMImageOwner) {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: jacob is never called, remove
    }

    public func preprocessingCompleteOperation(for imageOwner: ZMImageOwner) -> Operation? {
        // The completion owns the entered group independently of the preprocessor's lifetime.
        let group = processingGroup
        return BlockOperation {
            group.leave()
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
        NSOrderedSet(array: [ZMImageFormat.medium.rawValue])
    }

    func originalImageData() -> Data? {
        asset.original
    }

}
