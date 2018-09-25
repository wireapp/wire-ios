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
import WireUtilities

public protocol LinkPreviewDetectorType {
    
    func downloadLinkPreviews(inText text: String, excluding: [Range<Int>], completion: @escaping ([LinkPreview]) -> Void)
    
}

public final class LinkPreviewDetector : NSObject, LinkPreviewDetectorType {
    
    private let blacklist = PreviewBlacklist()
    private let linkDetector : NSDataDetector? = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    private let previewDownloader: PreviewDownloaderType
    private let imageDownloader: ImageDownloaderType
    private let workerQueue: OperationQueue
    
    public typealias DetectCompletion = ([LinkPreview]) -> Void
    typealias URLWithRange = (URL: URL, range: NSRange)
    
    public convenience override init() {
        let workerQueue = OperationQueue()
        self.init(
            previewDownloader: PreviewDownloader(resultsQueue: workerQueue),
            imageDownloader: ImageDownloader(resultsQueue: workerQueue),
            workerQueue: workerQueue
        )
    }
    
    init(previewDownloader: PreviewDownloaderType, imageDownloader: ImageDownloaderType, workerQueue: OperationQueue) {
        self.workerQueue = workerQueue
        self.previewDownloader = previewDownloader
        self.imageDownloader = imageDownloader
        super.init()
    }
    
    func containsLink(inText text: String) -> Bool {
        return !containedLinks(inText: text, excluding: []).isEmpty
    }
    
    /// Return URLs found in text together with their range in within the text
    /// parameter text: text in which to search for URLs
    /// parameter excluding: ranges (UTF-16) within the text which should we excluded from the search.
    func containedLinks(inText text: String, excluding: [Range<Int>] = []) -> [URLWithRange] {
        
        let wholeTextRange = Range<Int>(text.startIndex.encodedOffset...text.endIndex.encodedOffset)
        let validRangeIndexSet = IndexSet(integersIn: wholeTextRange, excluding: excluding)
        
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let matches = linkDetector?.matches(in: text, options: [], range: range) else { return [] }
        return matches.compactMap {
            guard let url = $0.url,
                  let range = Range<Int>($0.range),
                  validRangeIndexSet.contains(integersIn: range) else { return nil }
            return (url, $0.range)
        }
    }

    /**
     Downloads the link preview data, including their images, for links contained in the text.
     The preview data is generated from the [Open Graph](http://ogp.me) information contained in the head of the html of the link.
     For debugging Open Graph please use the [Sharing Debugger](https://developers.facebook.com/tools/debug/sharing).

     The completion block will be called on private background queue, make sure to switch to main or other queue.

     **Attention: For now this method only downloads the preview data (and only one image for this link preview) 
     for the first link found in the text!**

     - parameter text:       The text with potentially contained links, if links are found the preview data is downloaded.
     - parameter exluding:   Ranges in the text which should be skipped when searching for links.
     - parameter completion: The completion closure called when the link previews (and it's images) have been downloaded.
     */
    public func downloadLinkPreviews(inText text: String, excluding: [Range<Int>] = [], completion : @escaping DetectCompletion) {
        guard let (url, range) = containedLinks(inText: text, excluding: excluding).first, !blacklist.isBlacklisted(url) else { return completion([]) }
        previewDownloader.requestOpenGraphData(fromURL: url) { [weak self] openGraphData in
            guard let `self` = self else { return }
            let originalURLString = (text as NSString).substring(with: range)
            guard let data = openGraphData else { return completion([]) }

            let linkPreview = data.linkPreview(originalURLString, offset: range.location)
            linkPreview.requestAssets(withImageDownloader: self.imageDownloader) { _ in
                completion([linkPreview])
            }
        }
    }

    deinit {
        previewDownloader.tearDown()
    }
    
}
