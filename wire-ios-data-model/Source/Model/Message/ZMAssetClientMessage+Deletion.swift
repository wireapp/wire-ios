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

public extension Notification.Name {
    /// Notification to be fired when a (v3) asset should be deleted,
    /// which is only possible to be done by the original uploader of the asset.
    /// When firing this notification the asset id has to be included as object in the notification.
    static let deleteAssetNotification = Notification.Name("deleteAssetNotification")
}

/// A pending message that can be deleted locally while nobody else has it yet.
public protocol PendingMessageDeletable: ZMOTRMessage {

    /// Whether the message can be deleted without sending a delete.
    var isDeletableWhilePending: Bool { get }

    /// Deletes the message without sending a delete. Call it on the sync context.
    ///
    /// - Returns: `false` if the message can no longer be deleted this way, e.g. because sending started.
    @discardableResult
    func deletePendingMessage() -> Bool
}

extension ZMClientMessage: PendingMessageDeletable {}

extension ZMAssetClientMessage: PendingMessageDeletable {

    /// Whether the asset can be deleted without sending a delete, because it's still uploading. The asset
    /// message is only sent once the upload has succeeded, so nobody else has it.
    public var isDeletableWhilePending: Bool {
        guard
            DeveloperFlag.offlinePendingMessages.isOn,
            !isEphemeral,
            !isExpired,
            !delivered,
            transferState == .uploading,
            let sender, sender.isSelfUser
        else {
            return false
        }
        return true
    }

    /// Deletes an asset that is still uploading, without sending a delete.
    ///
    /// Call it on the sync context, where the asset message is sent once the upload has succeeded, so it
    /// can't be deleted while it's being sent.
    @discardableResult
    public func deletePendingMessage() -> Bool {
        guard isDeletableWhilePending, let managedObjectContext else { return false }

        // Cancel and save first, so the upload strategy also cancels a running upload request.
        cancelTransfer()
        managedObjectContext.saveOrRollback()

        removeClearingSender(true)
        managedObjectContext.delete(self)
        return true
    }
}

extension ZMAssetClientMessage {

    func deleteContent() {
        managedObjectContext?.zm_fileAssetCache.deleteAssetData(self)

        if let url = temporaryDirectoryURL,
           FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        dataSet.compactMap { $0 as? ZMGenericMessageData }.forEach {
            $0.managedObjectContext?.delete($0)
        }
        dataSet = NSOrderedSet()
        cachedUnderlyingAssetMessage = nil
        assetId = nil
        associatedTaskIdentifier = nil
        preprocessedSize = CGSize.zero
    }

    public override func removeClearingSender(_ clearingSender: Bool) {
        if !clearingSender {
            markRemoteAssetToBeDeleted()
        }
        deleteContent()
        super.removeClearingSender(clearingSender)
    }

    private func markRemoteAssetToBeDeleted() {
        guard sender == ZMUser.selfUser(in: managedObjectContext!) else {
            return
        }

        // Request the asset to be deleted
        if let identifier = underlyingMessage?.v3_uploadedAssetId {
            NotificationCenter.default.post(name: .deleteAssetNotification, object: identifier)
        }

        // Request the preview asset to be deleted
        if let previewIdentifier = underlyingMessage?.previewAssetId {
            NotificationCenter.default.post(name: .deleteAssetNotification, object: previewIdentifier)
        }
    }
}
