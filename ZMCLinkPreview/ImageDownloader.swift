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

public protocol ImageDownloaderType {
    func downloadImage(fromURL url: NSURL, completion: NSData? -> Void)
    func downloadImages(fromURLs urls: [NSURL], completion: [NSURL: NSData] -> Void)
}

public final class ImageDownloader: NSObject, ImageDownloaderType {
    
    public typealias ImageData = NSData
    
    let workerQueue: NSOperationQueue
    let resultsQueue: NSOperationQueue
    let session: URLSessionType
    
    init(resultsQueue: NSOperationQueue, workerQueue: NSOperationQueue = NSOperationQueue(), session: URLSessionType? = nil) {
        self.resultsQueue = resultsQueue
        self.workerQueue = workerQueue
        self.workerQueue.name = String(self.dynamicType) + "Queue"
        workerQueue.maxConcurrentOperationCount = 3
        workerQueue.qualityOfService = .Default
        self.session = session ?? NSURLSession(configuration: .ephemeralSessionConfiguration())
        super.init()
    }
    
    public func downloadImage(fromURL url: NSURL, completion: ImageData? -> Void) {
        downloadImages(fromURLs: [url]) { imagesByURL in
            completion(imagesByURL.values.first)
        }
    }
    
    public func downloadImages(fromURLs urls: [NSURL], completion: [NSURL: ImageData] -> Void) {
        workerQueue.addOperationWithBlock { [weak self] in
            guard let `self` = self else { return }
            var result = [NSURL: ImageData]()
            let group = dispatch_group_create()
            
            urls.forEach { url in
                dispatch_group_enter(group)
                self.session.dataTaskWithURL(url) { data, response, _ in
                    if let httpResponse = response as? NSHTTPURLResponse where httpResponse.contentTypeImage {
                        result[url] = data
                    }
                    dispatch_group_leave(group)
                }.resume()
            }
            
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
            self.resultsQueue.addOperationWithBlock {
                completion(result)
            }
        }
    }
    
}

extension NSHTTPURLResponse {

    var contentTypeImage: Bool {
        let contentTypeKey = HeaderKey.ContentType.rawValue
        guard let contentType = allHeaderFields[contentTypeKey] as? String ?? allHeaderFields[contentTypeKey.lowercaseString] as? String else { return false }
        return contentType.containsString("image")
    }

}
