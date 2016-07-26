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

private let userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

protocol PreviewDownloaderType {
    func requestOpenGraphData(fromURL url: NSURL, completion: OpenGraphData? -> Void)
}

enum HeaderKey: String {
    case UserAgent = "User-Agent"
    case ContentType = "Content-Type"
}

public class PreviewDownloader: NSObject, NSURLSessionDataDelegate, PreviewDownloaderType {
    
    public typealias DownloadCompletion = OpenGraphData? -> Void
    
    var containerByTaskID = [Int: MetaStreamContainer]()
    var completionByURL = [NSURL: DownloadCompletion]()
    var session: URLSessionType! = nil
    let resultsQueue: NSOperationQueue
    let parsingQueue: NSOperationQueue
    
    init(resultsQueue: NSOperationQueue, parsingQueue: NSOperationQueue? = nil, urlSession: URLSessionType? = nil) {
        self.resultsQueue = resultsQueue
        self.parsingQueue = parsingQueue ?? NSOperationQueue()
        self.parsingQueue.name = String(self.dynamicType) + "Queue"
        super.init()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        configuration.HTTPAdditionalHeaders = [HeaderKey.UserAgent.rawValue: userAgent] // Override the user agent to not get served mobile pages
        session = urlSession ?? NSURLSession(configuration: configuration, delegate: self, delegateQueue: parsingQueue)
    }
    
    func requestOpenGraphData(fromURL url: NSURL, completion: DownloadCompletion) {
        completionByURL[url] = completion
        session.dataTaskWithURL(url).resume()
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        processReceivedData(data, forTask: dataTask, withIdentifier: dataTask.taskIdentifier)
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        URLSession(session as URLSessionType , task: task as URLSessionDataTaskType, didCompleteWithError: error)
    }
    
    func URLSession(session: URLSessionType, task: URLSessionDataTaskType, didCompleteWithError error: NSError?) {
        guard let errorCode = error?.code where errorCode != NSURLError.Cancelled.rawValue else { return }
        guard let url = task.originalRequest?.URL, completion = completionByURL[url] where error != nil else { return }
        completeAndCleanUp(completion, result: nil, url: url, taskIdentifier: task.taskIdentifier)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        guard let httpResponse = response as? NSHTTPURLResponse else { return }
        URLSession(session, dataTask: dataTask, didReceiveHTTPResponse: httpResponse, completionHandler: completionHandler)
    }
    
    func URLSession(session: URLSessionType, dataTask: URLSessionDataTaskType, didReceiveHTTPResponse response: NSHTTPURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        guard let url = dataTask.originalRequest?.URL, completion = completionByURL[url] else { return }
        let (headers, contentTypeKey) = (response.allHeaderFields, HeaderKey.ContentType.rawValue)
        let contentType = headers[contentTypeKey] as? String ?? headers[contentTypeKey.lowercaseString] as? String
        if let contentType = contentType where !contentType.lowercaseString.containsString("text/html") {
            completeAndCleanUp(completion, result: nil, url: url, taskIdentifier: dataTask.taskIdentifier)
            return completionHandler(.Cancel)
        }
        
        return completionHandler(.Allow)
    }

    func processReceivedData(data: NSData, forTask task: URLSessionDataTaskType, withIdentifier identifier: Int) {
        let container = containerByTaskID[identifier] ?? MetaStreamContainer()
        container.addData(data)
        containerByTaskID[identifier] = container

        guard container.reachedEndOfHead,
            let url = task.originalRequest?.URL,
            completion = completionByURL[url] else { return }

        task.cancel()
        
        parseMetaHeader(container, url: url) { [weak self] result in
            guard let `self` = self else { return }
            self.completeAndCleanUp(completion, result: result, url: url, taskIdentifier: identifier)
        }
    }
    
    func completeAndCleanUp(completion: DownloadCompletion, result: OpenGraphData?, url: NSURL, taskIdentifier: Int) {
        completion(result)
        self.containerByTaskID[taskIdentifier] = nil
        self.completionByURL[url] = nil
    }

    func parseMetaHeader(container: MetaStreamContainer, url: NSURL, completion: DownloadCompletion) {
        guard let xmlString = container.head else { return completion(nil) }
        let scanner = OpenGraphScanner(xmlString, url: url) { [weak self] result in
            self?.resultsQueue.addOperationWithBlock {
                completion(result)
            }
        }
        
        scanner.parse()
    }
}
