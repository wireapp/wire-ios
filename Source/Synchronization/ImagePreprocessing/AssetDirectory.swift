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
import ZMCSystem
import zimages

private let zmLog = ZMSLog(tag: "Assets")

/// A directory manages access to asset files
public class AssetDirectory : NSObject {
    
    let cacheFolderURL : NSURL!
    
    public override init() {
        // if this fails, we can't write to disk - better crash
        self.cacheFolderURL = (NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first)!
    }
    
    /// Returns the asset data for a given message and format tag. This will probably cause I/O
    public func assetData(messageID: NSUUID, format: ZMImageFormat, encrypted: Bool) -> NSData? {
        let url = URLForAsset(messageID, format: format, encrypted: encrypted)
        let data: NSData?
        do {
            data = try NSData(contentsOfURL: url, options: .DataReadingMappedIfSafe)
        }
        catch let error as NSError {
            if error.code != NSFileReadNoSuchFileError {
                zmLog.error("\(error)")
            }
            data = nil
        }
        return data
    }
    
    /// Sets the asset data for a given message and format tag. This will cause I/O
    public func storeAssetData(messageID: NSUUID, format: ZMImageFormat, encrypted: Bool, data: NSData) {
        let url = URLForAsset(messageID, format: format, encrypted: encrypted)
        let ptr = NSErrorPointer()
        if url.checkResourceIsReachableAndReturnError(ptr) {
            return
        }
        
        do {
            try data.writeToURL(url, options: .AtomicWrite)
        }
        catch let error as NSError {
            zmLog.error("Can't write to file \(url.pathComponents!.last!): \(error)")
        }
    }
    
    /// Deletes the data for a given message and format tag. This will cause I/O
    public func deleteAssetData(messageID: NSUUID, format: ZMImageFormat, encrypted: Bool) {
        let url = URLForAsset(messageID, format: format, encrypted: encrypted)
        do {
            try NSFileManager.defaultManager().removeItemAtURL(url)

        }
        catch let error as NSError {
            zmLog.warn("Could not delete asset data \(url.pathComponents!.last!)")
            if error.code != NSFileReadNoSuchFileError {
                zmLog.error("Can't delete file \(url.pathComponents!.last!): \(error)")
            }
        }
    }
    
    /// Returns the expected filename of an asset
    public func URLForAsset(messageID: NSUUID, format: ZMImageFormat) -> NSURL {
        return self.URLForAsset(messageID, format: format, encrypted: false);
    }
    
    /// Returns the expected filename of an asset, encrypted or decrypted
    private func URLForAsset(messageID: NSUUID, format: ZMImageFormat, encrypted: Bool) -> NSURL {
        let tagComponent = StringFromImageFormat(format)
        let encryptedComponent = encrypted ? "_encrypted" : ""
        let filename = "\(messageID.transportString())_\(tagComponent)\(encryptedComponent)"
        return self.URLForFile(filename)
    }
    
    /// Returns the URL for a file path
    private func URLForFile(fileName: String) -> NSURL {
        return self.cacheFolderURL.URLByAppendingPathComponent(fileName).URLByAppendingPathExtension("zass")
    }
    
    /// Lists the file for a given message. Used for debugging
    public func assetFilesForMessage(messageID: NSUUID) -> [NSURL] {
        return allFiles().filter { (url : NSURL) in
            if let last = url.pathComponents?.last {
                return last.hasPrefix(messageID.transportString())
            }
            return false;
        }
    }
    
    /// List all files in the cache. Used for debugging
    public func allFiles() -> [NSURL] {
        let list : [NSURL]
        do  {
          list = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(
            self.cacheFolderURL,
            includingPropertiesForKeys: [NSURLNameKey],
            options: NSDirectoryEnumerationOptions())
        }
        catch let error as NSError {
            zmLog.error("Can't retrieve all files in cache: \(error)")
            list = []
        }
        return list
    }
}
