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


public typealias SuccessOrErrorCallback = (success:Bool, error:NSError?)->()
public typealias FetchBlock = (offset:Int)->()

public class ZiphyPaginationController {
    
    private(set) public var ziphs:[Ziph]?
    
    private (set) var ziphsThisFetch = 0
    private (set) public var totalPagesFetched = 0

    private var offset = 0
    
    public var fetchBlock:FetchBlock?
    public var completionBlock:SuccessOrErrorCallback?
    public var callBackQueue:dispatch_queue_t
    
    
    public init(callBackQueue:dispatch_queue_t = dispatch_get_main_queue()){
        
        self.callBackQueue = callBackQueue;
    }
    
    public func fetchNewPage() {
        
        self.fetchNewPage(self.offset)
    }
    
    private func fetchNewPage(offset:Int) {
        
        self.fetchBlock?(offset: offset)
    }
    
    public func updatePagination(success:Bool, ziphs:[Ziph], error:NSError?) {
        
        self.ziphsThisFetch = ziphs.count
        
        if (success) {
            
            self.totalPagesFetched += 1
            self.ziphs = (self.ziphs ?? []) + ziphs
            self.offset = self.ziphs!.count
        }
        
        performOnQueue(self.callBackQueue){
            self.completionBlock?(success: success, error: error)
        }
    }
}