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
import zmessaging

@objc class AnalyticsFileTransferObserver: NSObject {
    let analyticsTracker: AnalyticsTracker = AnalyticsTracker(context: "")
    
    override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnalyticsFileTransferObserver.uploadFinishedNotification(_:)), name: FileUploadRequestStrategyNotification.uploadFinishedNotificationName, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnalyticsFileTransferObserver.uploadFailedNotification(_:)), name: FileUploadRequestStrategyNotification.uploadFailedNotificationName, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnalyticsFileTransferObserver.downloadFinishedNotification(_:)), name: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnalyticsFileTransferObserver.downloadFailedNotification(_:)), name: AssetDownloadRequestStrategyNotification.downloadFailedNotificationName, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func uploadFinishedNotification(notification: NSNotification?) {
        guard let message = notification?.object as? ZMConversationMessage,
              let startTime = notification?.userInfo?[FileUploadRequestStrategyNotification.requestStartTimestampKey] as? NSDate,
              let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagSucceededFileUploadWithSize(fileMessageData.size, fileExtension: (fileMessageData.filename as NSString).pathExtension, duration: fabs(startTime.timeIntervalSinceNow))
    }
    
    func uploadFailedNotification(notification: NSNotification?) {
        guard let message = notification?.object as? ZMConversationMessage,
              let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagFailedFileUploadWithSize(fileMessageData.size, fileExtension: (fileMessageData.filename as NSString).pathExtension)
    }
    
    func downloadFinishedNotification(notification: NSNotification?) {
        guard let message = notification?.object as? ZMConversationMessage,
            let startTime = notification?.userInfo?[AssetDownloadRequestStrategyNotification.downloadStartTimestampKey] as? NSDate,
            let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagSuccededFileDownloadWithSize(fileMessageData.size, fileExtension: (fileMessageData.filename as NSString).pathExtension, duration: fabs(startTime.timeIntervalSinceNow))
    }
    
    func downloadFailedNotification(notification: NSNotification?) {
        guard let message = notification?.object as? ZMConversationMessage,
            let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagFailedFileDownloadWithSize(fileMessageData.size, fileExtension: (fileMessageData.filename as NSString).pathExtension)
    }
    
}

