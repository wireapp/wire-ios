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


@objc public class LinkPreview : NSObject {
    
    public let originalURLString: String
    public let permanentURL: NSURL?
    public let characterOffsetInText: Int
    public var imageURLs = [NSURL]()
    public var imageData = [NSData]()
    
    public typealias DownloadCompletion = (successful: Bool) -> Void
    
    public init(originalURLString: String, permamentURLString: String, offset: Int) {
        self.originalURLString = originalURLString
        permanentURL = NSURL(string: permamentURLString)
        characterOffsetInText = offset
        super.init()
    }
    
    func requestAssets(withImageDownloader downloader: ImageDownloaderType, completion: DownloadCompletion) {
        guard let imageURL = imageURLs.first else { return completion(successful: false) }
        downloader.downloadImage(fromURL: imageURL) { [weak self] imageData in
            guard let `self` = self, data = imageData else { return completion(successful: false) }
            self.imageData.append(data)
            completion(successful: imageData != nil)
        }
    }

}


@objc public class Article : LinkPreview {
    public var title : String?
    public var summary : String?
}

@objc public class FoursquareLocation : LinkPreview {
    public var title : String?
    public var subtitle : String?
    public var latitude: Float?
    public var longitude: Float?
}

@objc public class InstagramPicture : LinkPreview {
    public var title : String?
    public var subtitle : String?
}

@objc public class TwitterStatus : LinkPreview {
    public var message : String?
    public var username : String?
    public var author : String?
}
