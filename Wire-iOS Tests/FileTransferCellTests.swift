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


import XCTest
@testable import Wire

@objc class FileTransferCellTests: ZMSnapshotTestCase {
    
    func cellWithConfig(config: ((MockMessage) -> ())?) -> FileTransferCell {
    
        let fileMessage = MockMessageFactory.fileTransferMessage()
        
        if let config = config {
            config(fileMessage)
        }
        
        let cell = FileTransferCell(style: .Default, reuseIdentifier: "test")
        
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        
        cell.prepareForReuse()
        cell.bounds = CGRectMake(0.0, 0.0, 320.0, 9999)
        cell.contentView.bounds = CGRectMake(0.0, 0.0, 320, 9999)
        cell.layer.speed = 0;
        
        cell.layoutMargins = UIEdgeInsetsMake(0, CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin")),
        0, CGFloat(WAZUIMagic.floatForIdentifier("content.right_margin")))
        
        cell.configureForMessage(fileMessage, layoutProperties: layoutProperties)
        cell.layoutIfNeeded()

        let size = cell.systemLayoutSizeFittingSize(CGSizeMake(320.0, 0.0) , withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
        cell.bounds = CGRectMake(0.0, 0.0, size.width, size.height)
        cell.layoutIfNeeded()
        return cell
    }
    
    override func setUp() {
        super.setUp()
        self.accentColor = .VividRed
    }
   
    func testUploadedCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        })
        verify(view: cell)
    }
    
    func testUploadedCell_fromOtherDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.backingFileMessageData.fileURL = .None
        })
        verify(view: cell)
    }
    
    func testUploadedCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.backingFileMessageData.fileURL = .None
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    
    
    func testUploadedCell_fromThisDevice_longFileName() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.fileMessageData?.filename = "Etiam lacus elit, tempor at blandit sit amet, faucibus in erat. Mauris faucibus scelerisque mattis.pdf"
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        })
        verify(view: cell)
    }
    
    func testUploadedCell_fromThisDevice_bigFileSize() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.fileMessageData?.size = 1024 * 1024 * 25
            $0.backingFileMessageData.fileURL = .None
        })
        verify(view: cell)
    }
    
    
    func testUploadingCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploading
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        })
        verify(view: cell)
    }
    
    func testUploadingCell_fromOtherDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploading
            $0.backingFileMessageData.fileURL = .None
        })
        verify(view: cell)
    }
    
    func testUploadingCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploading
            $0.backingFileMessageData.fileURL = .None
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    
    
    func testDownloadingCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloading
            $0.fileMessageData?.progress = 0.75
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        })
        verify(view: cell)
    }
    
    func testDownloadingCell_fromOtherDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloading
            $0.fileMessageData?.progress = 0.75
            $0.backingFileMessageData.fileURL = .None
        })
        verify(view:cell)
    }
    
    func testDownloadingCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloading
            $0.backingFileMessageData.fileURL = .None
            $0.fileMessageData?.progress = 0.75
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    
    
    func testDownloadedCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloaded
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        })
        verify(view: cell)
    }
    
    func testDownloadedCell_fromOtherDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloaded
            $0.backingFileMessageData.fileURL = .None
        })
        verify(view: cell)
    }
    
    func testDownloadedCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloaded
            $0.backingFileMessageData.fileURL = .None
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    
    
    func testFailedDownloadCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedDownload
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        })
        verify(view: cell)
    }
    
    func testFailedDownloadCell_fromOtherDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedDownload
            $0.backingFileMessageData.fileURL = .None
        })
        verify(view: cell)
    }
    
    func testFailedDownloadCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedDownload
            $0.backingFileMessageData.fileURL = .None
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    
    
    
    func testFailedUploadCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedUpload
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        })
        verify(view: cell)
    }
    
    func testFailedUploadCell_fromOtherDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedUpload
            $0.backingFileMessageData.fileURL = .None
        })
        verify(view: cell)
    }
    
    func testFailedUploadCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedUpload
            $0.backingFileMessageData.fileURL = .None
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    // MARK : Upload Cancelled
    
    func testCancelledUploadCell_fromThisDevice() {
        let cell = cellWithConfig {
            $0.fileMessageData?.transferState = .CancelledUpload
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
        }
        
        verify(view: cell)
    }
}
