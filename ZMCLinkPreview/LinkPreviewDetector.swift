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

public class LinkPreviewDetector : NSObject {
    
    private let blacklist = PreviewBlacklist()
    private let linkDetector : NSDataDetector? = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
    private let previewDownloader: PreviewDownloaderType
    private let imageDownloader: ImageDownloaderType
    private let workerQueue: NSOperationQueue
    private let resultsQueue: NSOperationQueue
    
    public typealias DetectCompletion = [LinkPreview] -> Void
    typealias URLWithRange = (URL: NSURL, range: NSRange)
    
    public convenience init(resultsQueue: NSOperationQueue) {
        let workerQueue = NSOperationQueue()
        self.init(
            previewDownloader: PreviewDownloader(resultsQueue: workerQueue),
            imageDownloader: ImageDownloader(resultsQueue: workerQueue),
            resultsQueue: resultsQueue,
            workerQueue: workerQueue
        )
    }
    
    init(previewDownloader: PreviewDownloaderType, imageDownloader: ImageDownloaderType, resultsQueue: NSOperationQueue, workerQueue: NSOperationQueue) {
        self.resultsQueue = resultsQueue
        self.workerQueue = workerQueue
        self.previewDownloader = previewDownloader
        self.imageDownloader = imageDownloader
        super.init()
    }
    
    public func containsLink(inText text: String) -> Bool {
        return !containedLinks(inText: text).isEmpty
    }
    
    func containedLinks(inText text: String) -> [URLWithRange] {
        let range = NSRange(location: 0, length: text.characters.count)
        guard let matches = linkDetector?.matchesInString(text, options: [], range: range) else { return [] }
        return matches.flatMap {
            guard let url = $0.URL else { return nil }
            return (url, $0.range)
        }
    }

    /**
     Downloads the link preview data, including their images, for links contained in the text.
     The preview data is generated from the [Open Graph](http://ogp.me) information contained in the head of the html of the link.
     For debugging Open Graph please use the [Sharing Debugger](https://developers.facebook.com/tools/debug/sharing).

     **Attention: For now this method only downloads the preview data (and only one image for this link preview) 
     for the first link found in the text!**

     - parameter text:       The text with potentially contained links, if links are found the preview data is downloaded.
     - parameter completion: The completion closure called when the link previews (and it's images) have been downloaded.
     */
    public func downloadLinkPreviews(inText text: String, completion : DetectCompletion) {
        guard let (url, range) = containedLinks(inText: text).first where !blacklist.isBlacklisted(url) else { return callCompletion(completion, result: []) }
        previewDownloader.requestOpenGraphData(fromURL: url) { [weak self] openGraphData in
            guard let `self` = self else { return }
            let originalURLString = (text as NSString).substringWithRange(range)
            guard let data = openGraphData else { return self.callCompletion(completion, result: []) }

            let linkPreview = data.linkPreview(originalURLString, offset: range.location)
            linkPreview.requestAssets(withImageDownloader: self.imageDownloader) { _ in
                self.callCompletion(completion, result: [linkPreview])
            }
        }
    }
    
    private func callCompletion(completion: DetectCompletion, result: [LinkPreview]) {
        resultsQueue.addOperationWithBlock { 
            completion(result)
        }
    }
    
}
