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

extension ZMAssetClientMessage {

    func deleteContent() {
        
        if self.imageMessageData != nil || self.fileMessageData != nil,
            let assetCache = self.managedObjectContext?.zm_imageAssetCache
        {
            [
                ZMImageFormat.medium,
                ZMImageFormat.original,
                ZMImageFormat.preview,
                ZMImageFormat.profile
            ].forEach { format in
                assetCache.deleteAssetData(self.nonce, format: format, encrypted: true)
                assetCache.deleteAssetData(self.nonce, format: format, encrypted: false)
            }
        }
        
        if self.fileMessageData != nil,
            let fileCache = self.managedObjectContext?.zm_fileAssetCache,
            let filename = self.filename
        {
            fileCache.deleteAssetData(self.nonce, fileName: filename, encrypted: false)
            fileCache.deleteAssetData(self.nonce, fileName: filename, encrypted: true)
        }
        
        self.dataSet = NSOrderedSet()
        self.cachedGenericAssetMessage = nil
        self.assetId = nil
        self.associatedTaskIdentifier = nil
        self.preprocessedSize = CGSize.zero
    }
    
    override public func removeClearingSender(_ clearingSender: Bool) {
        self.deleteContent()
        super.removeClearingSender(clearingSender)
    }
}
