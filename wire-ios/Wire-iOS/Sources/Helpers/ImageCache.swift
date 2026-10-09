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

import UIKit

// swiftlint:disable:next todo_requires_jira_link
// TODO: remove public after MockUser is convert to Swift
final class ImageCache<T: AnyObject> {
    var cache: NSCache<NSString, T> = NSCache()
    var processingQueue = DispatchQueue(label: "ImageCacheQueue", qos: .background, attributes: [.concurrent])
    var dispatchGroup: DispatchGroup = .init()

    private var backgroundObserver: (any NSObjectProtocol)?

    init() {
        // Drop decoded images when the app is backgrounded. NSCache only evicts reliably
        // while in the foreground, so without this the cached images stay resident and inflate
        // the suspended app's memory footprint, making it a prime target for jetsam
        // ("System Pressure" background terminations).
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
    }

    deinit {
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
    }
}

extension UIImage {
    static var defaultUserImageCache: ImageCache<UIImage> = ImageCache()
}

enum MediaAssetCache {
    static var defaultImageCache = ImageCache<AnyObject>()
}
