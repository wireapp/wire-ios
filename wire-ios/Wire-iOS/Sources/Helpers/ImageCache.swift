//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import UIKit

// swiftlint:disable todo_requires_jira_link
// TODO: remove public after MockUser is convert to Swift
// swiftlint:enable todo_requires_jira_link
final class ImageCache<T: AnyObject> {
    var cache: NSCache<NSString, T> = NSCache()
    var processingQueue = DispatchQueue(label: "ImageCacheQueue", qos: .background, attributes: [.concurrent])
    var dispatchGroup: DispatchGroup = DispatchGroup()
}

extension UIImage {
    static var defaultUserImageCache: ImageCache<UIImage> = ImageCache()
}

final class MediaAssetCache {
    static var defaultImageCache = ImageCache<AnyObject>()
}
