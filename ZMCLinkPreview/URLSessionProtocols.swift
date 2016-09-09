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

typealias DataTaskCompletion = (Data?, URLResponse?, NSError?) -> Void

protocol URLSessionType {
    func dataTaskWithURL(_ url: URL) -> URLSessionDataTaskType
    func dataTaskWithURL(_ url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskType
}

protocol URLSessionDataTaskType {
    func resume()
    func cancel()
    
    var originalRequest: URLRequest? { get }
    var taskIdentifier: Int { get }
}

extension URLSessionTask: URLSessionDataTaskType {}

extension URLSession: URLSessionType {
    func dataTaskWithURL(_ url: URL) -> URLSessionDataTaskType {
        return (dataTask(with: url) as URLSessionDataTask) as URLSessionDataTaskType
    }
    
    func dataTaskWithURL(_ url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskType {
        return (dataTask(with: url, completionHandler: completionHandler as! (Data?, URLResponse?, Error?) -> Void) as URLSessionDataTask) as URLSessionDataTaskType
    }
}
