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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import Foundation
import ZMTransport

/// Perform requests to the Giphy search API
@objc public class GiphyRequestStrategy : NSObject, RequestStrategy {
    
    /// URL on the backend to handle giphy requests
    private static let UrlPrefix = "giphy"
    
    /// The requests to fulfill
    private weak var requestsStatus : GiphyRequestsStatus?
    
    /// The managed object context to operate on
    private let managedObjectContext : NSManagedObjectContext
    
    /// Requests fail after this interval if the network is unreachable
    private static let RequestExpirationTime : NSTimeInterval = 20
    
    public init(requestsStatus: GiphyRequestsStatus, managedObjectContext: NSManagedObjectContext) {
        self.requestsStatus = requestsStatus
        self.managedObjectContext = managedObjectContext
    }
    
    public func nextRequest() -> ZMTransportRequest? {
        
        guard let status = self.requestsStatus else { return nil }
        
        if(status.pendingRequests.count > 0) {
            let (url, callback) = status.pendingRequests.removeAtIndex(0)
            let request = ZMTransportRequest(getFromPath: NSString.pathWithComponents([GiphyRequestStrategy.UrlPrefix, url.relativeString!]))
            request.expireAfterInterval(GiphyRequestStrategy.RequestExpirationTime)
            request.addCompletionHandler(ZMCompletionHandler(onGroupQueue: self.managedObjectContext, block: {
                response in
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(response.rawData, response.rawResponse, response.transportSessionError)
                    })
                return
            }))
            return request
        }
        
        return nil
    }
    
    /**
    Schedules a request to be sent to the backend.
    
    - parameter timeout: If it is not completed in the given interval, the request is completed with error
    */
    public func scheduleAuthenticatedRequestWithCompletionHandler(relativeUrl: NSURL, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void), timeout: NSTimeInterval) {
        
    }
}
