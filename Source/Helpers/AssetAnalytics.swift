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
import ZMCDataModel

@objc public final class FileUploadRequestStrategyNotification: NSObject {
    public static let uploadFinishedNotificationName = "FileUploadRequestStrategyUploadFinishedNotificationName"
    public static let requestStartTimestampKey = "requestStartTimestamp"
    public static let uploadFailedNotificationName = "FileUploadRequestStrategyUploadFailedNotificationName"
}

final public class AssetAnalytics {

    private let moc: NSManagedObjectContext
    private let notificationCenter = NotificationCenter.default

    init(managedObjectContext: NSManagedObjectContext) {
        moc = managedObjectContext
    }

    func trackUploadFinished(for message: ZMAssetClientMessage, with response: ZMTransportResponse) {
        let messageObjectId = message.objectID

        moc.zm_userInterface.performGroupedBlock {
            self.notificationCenter.post(
                name: NSNotification.Name(rawValue: FileUploadRequestStrategyNotification.uploadFinishedNotificationName),
                object: try? self.moc.zm_userInterface.existingObject(with: messageObjectId),
                userInfo: [FileUploadRequestStrategyNotification.requestStartTimestampKey: response.startOfUploadTimestamp]
            )
        }
    }

    func trackUploadFailed(for message: ZMAssetClientMessage, with request: ZMTransportRequest?) {
        let messageObjectId = message.objectID

        moc.zm_userInterface.performGroupedBlock {
            self.notificationCenter.post(
                name: NSNotification.Name(rawValue: FileUploadRequestStrategyNotification.uploadFailedNotificationName),
                object: try? self.moc.zm_userInterface.existingObject(with: messageObjectId),
                userInfo: [FileUploadRequestStrategyNotification.requestStartTimestampKey: request?.startOfUploadTimestamp != nil ?? Date()]
            )
        }
    }

}
