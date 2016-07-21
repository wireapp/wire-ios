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

public typealias DataTaskCompletion = (NSData?, NSURLResponse?, NSError?) -> Void

public protocol URLSessionType {
    func dataTaskWithURL(url: NSURL) -> URLSessionDataTaskType
    func dataTaskWithURL(url: NSURL, completionHandler: DataTaskCompletion) -> URLSessionDataTaskType
}

public protocol URLSessionDataTaskType {
    func resume()
    func cancel()
    
    var originalRequest: NSURLRequest? { get }
    var taskIdentifier: Int { get }
}

extension NSURLSessionTask: URLSessionDataTaskType {}

extension NSURLSession: URLSessionType {
    public func dataTaskWithURL(url: NSURL) -> URLSessionDataTaskType {
        return (dataTaskWithURL(url) as NSURLSessionDataTask) as URLSessionDataTaskType
    }
    
    public func dataTaskWithURL(url: NSURL, completionHandler: DataTaskCompletion) -> URLSessionDataTaskType {
        return (dataTaskWithURL(url, completionHandler: completionHandler) as NSURLSessionDataTask) as URLSessionDataTaskType
    }
}
