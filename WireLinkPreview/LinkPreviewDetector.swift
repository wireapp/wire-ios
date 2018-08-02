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

@objc public protocol LinkPreviewDetectorType {
    @objc optional func downloadLinkPreviews(inText text: String, completion: @escaping ([LinkPreview]) -> Void)
    weak var delegate: LinkPreviewDetectorDelegate? { get set }
}

@objc public protocol LinkPreviewDetectorDelegate: class {
    func shouldDetectURL(_ url: URL, range: NSRange, text: String) -> Bool
}

public final class LinkPreviewDetector : NSObject, LinkPreviewDetectorType {
    
    public weak var delegate: LinkPreviewDetectorDelegate?
    
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
    
    public func containsLink(inText text: String) -> Bool {
        return !containedLinks(inText: text).isEmpty
    }
    
    func containedLinks(inText text: String) -> [URLWithRange] {
        let range = NSRange(location: 0, length: (text as NSString).length)
        guard let matches = linkDetector?.matches(in: text, options: [], range: range) else { return [] }
        return matches.compactMap {
            guard let url = $0.url,
                delegate?.shouldDetectURL(url, range: $0.range, text: text) ?? true
                else { return nil }
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
     - parameter completion: The completion closure called when the link previews (and it's images) have been downloaded.
     */
    public func downloadLinkPreviews(inText text: String, completion : @escaping DetectCompletion) {
        guard let (url, range) = containedLinks(inText: text).first, !blacklist.isBlacklisted(url) else { return completion([]) }
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
