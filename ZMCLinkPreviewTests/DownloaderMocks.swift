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


@testable import ZMCLinkPreview

class MockPreviewDownloader: PreviewDownloaderType {
    
    typealias Completion = OpenGraphData? -> Void
    
    var mockOpenGraphData: OpenGraphData? = nil
    var requestOpenGraphDataCallCount = 0
    var requestOpenGraphDataURLs = [NSURL]()
    var requestOpenGraphDataCompletions = [Completion]()
    
    func requestOpenGraphData(fromURL url: NSURL, completion: OpenGraphData? -> Void) {
        requestOpenGraphDataCallCount += 1
        requestOpenGraphDataURLs.append(url)
        requestOpenGraphDataCompletions.append(completion)
        completion(mockOpenGraphData)
    }
}

class MockImageDownloader: ImageDownloaderType {
    
    typealias ImageCompletion = NSData? -> Void
    var mockImageData: NSData? = nil
    var downloadImageURLs = [NSURL]()
    var downloadImageCallCount = 0
    var downloadImageCompletion = [ImageCompletion]()
    
    typealias ImagesCompletion = [NSURL : NSData] -> Void
    var mockImageDataByUrl = [NSURL: NSData]()
    var downloadImagesCallCount = 0
    var downloadImagesURLs = [NSURL]()
    var downloadImagesCompletion = [ImagesCompletion]()
    
    func downloadImage(fromURL url: NSURL, completion: NSData? -> Void) {
        downloadImageCallCount += 1
        downloadImageURLs.append(url)
        downloadImageCompletion.append(completion)
        completion(mockImageData)
    }
    
    func downloadImages(fromURLs urls: [NSURL], completion: [NSURL : NSData] -> Void) {
        downloadImagesCallCount += 1
        downloadImageURLs.appendContentsOf(urls)
        downloadImagesCompletion.append(completion)
        return completion(mockImageDataByUrl)
    }
}
