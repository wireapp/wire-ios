//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - LinkMetadata

@objcMembers
open class LinkMetadata: NSObject {
    public let originalURLString: String
    public let permanentURL: URL?
    public let resolvedURL: URL?
    public let characterOffsetInText: Int
    open var imageURLs = [URL]()
    open var imageData = [Data]()

    public typealias DownloadCompletion = (_ successful: Bool) -> Void

    public init(originalURLString: String, permanentURLString: String, resolvedURLString: String, offset: Int) {
        self.originalURLString = originalURLString
        self.permanentURL = URL(string: permanentURLString)
        self.resolvedURL = URL(string: resolvedURLString)
        self.characterOffsetInText = offset
        super.init()
    }

    public var isBlacklisted: Bool {
        if let permanentURL {
            PreviewBlacklist.isBlacklisted(permanentURL)
        } else if let resolvedURL {
            PreviewBlacklist.isBlacklisted(resolvedURL)
        } else {
            false
        }
    }

    func requestAssets(withImageDownloader downloader: ImageDownloaderType, completion: @escaping DownloadCompletion) {
        guard let imageURL = imageURLs.first else { return completion(false) }
        downloader.downloadImage(fromURL: imageURL) { [weak self] imageData in
            guard let self, let data = imageData else { return completion(false) }
            self.imageData.append(data)
            completion(imageData != nil)
        }
    }
}

// MARK: - ArticleMetadata

@objcMembers
public final class ArticleMetadata: LinkMetadata {
    public var title: String?
    public var summary: String?
}

// MARK: - FoursquareLocationMetadata

@objcMembers
public final class FoursquareLocationMetadata: LinkMetadata {
    public var title: String?
    public var subtitle: String?
    public var latitude: Float?
    public var longitude: Float?
}

// MARK: - InstagramPictureMetadata

@objcMembers
public final class InstagramPictureMetadata: LinkMetadata {
    public var title: String?
    public var subtitle: String?
}

// MARK: - TwitterStatusMetadata

@objcMembers
public final class TwitterStatusMetadata: LinkMetadata {
    public var message: String?
    public var username: String?
    public var author: String?
}
