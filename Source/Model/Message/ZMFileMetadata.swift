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
import MobileCoreServices
import ZMCSystem

private let zmLog = ZMSLog(tag: "ZMFileMetadata")


@objc public class ZMFileMetadata : NSObject {
    
    public let fileURL : NSURL
    public let thumbnail : NSData?
    
    required public init(fileURL: NSURL, thumbnail: NSData? = nil) {
        self.fileURL = fileURL
        self.thumbnail = thumbnail?.length > 0 ? thumbnail : nil
        
        super.init()
    }
    
    var asset : ZMAsset {
        get {
            return ZMAsset.asset(withOriginal: .original(withSize: size,
                mimeType: mimeType,
                name: filename)
            )
        }
    }
}


public class ZMAudioMetadata : ZMFileMetadata {
    
    public let duration : NSTimeInterval
    public let normalizedLoudness : [Float]
    
    required public init(fileURL: NSURL, duration: NSTimeInterval, normalizedLoudness: [Float] = [], thumbnail: NSData? = nil) {
        self.duration = duration
        self.normalizedLoudness = normalizedLoudness
        
        super.init(fileURL: fileURL, thumbnail: thumbnail)
    }
    
    required public init(fileURL: NSURL, thumbnail: NSData?) {
        self.duration = 0
        self.normalizedLoudness = []
        
        super.init(fileURL: fileURL, thumbnail: thumbnail)
    }
    
    override var asset : ZMAsset {
        get {
            return ZMAsset.asset(withOriginal: .original(withSize: size,
                mimeType: mimeType,
                name: filename,
                audioDurationInMillis: UInt(duration * 1000),
                normalizedLoudness: normalizedLoudness)
            )
        }
    }
    
}

public class ZMVideoMetadata : ZMFileMetadata {
    
    public let duration : NSTimeInterval
    public let dimensions : CGSize
    
    required public init(fileURL: NSURL, duration: NSTimeInterval, dimensions: CGSize, thumbnail: NSData? = nil) {
        self.duration = duration
        self.dimensions = dimensions
        
        super.init(fileURL: fileURL, thumbnail: thumbnail)
    }
    
    required public init(fileURL: NSURL, thumbnail: NSData?) {
        self.duration = 0
        self.dimensions = CGSizeZero
        
        super.init(fileURL: fileURL, thumbnail: thumbnail)
    }
    
    override var asset : ZMAsset {
        get {
            return ZMAsset.asset(withOriginal: .original(withSize: size,
                mimeType: mimeType,
                name: filename,
                videoDurationInMillis: UInt(duration * 1000),
                videoDimensions: dimensions)
            )
        }
    }
    
}

extension ZMFileMetadata {
    
    var mimeType : String {
        get {
            guard let pathExtension = fileURL.pathExtension,
                  let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue(),
                  let MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType) else {
                    return "application/octet-stream"
            }
            
            return (MIMEType.takeRetainedValue()) as String
        }
    }
    
    public var filename : String {
        get {
            return  fileURL.lastPathComponent ?? "unnamed"
        }
    }
    
    var size : UInt64 {
        get {
            do {
                let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(fileURL.path!)
                if let fileSize = attributes[NSFileSize] as? NSNumber {
                    return fileSize.unsignedLongLongValue
                }
            } catch {
                zmLog.error("Couldn't read file size of \(fileURL)")
                return 0
            }
            
            return 0
        }
    }
    
}
