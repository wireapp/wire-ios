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


public typealias SuccessOrErrorCallback = (_ success:Bool, _ ziphs:[Ziph], _ error:Error?)->()
public typealias FetchBlock = (_ offset:Int)-> CancelableTask?

@objcMembers public class ZiphyPaginationController {
    
    fileprivate(set) var ziphs: [Ziph] = []
    fileprivate (set) var ziphsThisFetch = 0
    fileprivate (set) open var totalPagesFetched = 0
    fileprivate var offset = 0
    
    open var fetchBlock:FetchBlock?
    open var completionBlock:SuccessOrErrorCallback?

    public init() {}
    
    open func fetchNewPage() -> CancelableTask? {
        
        return self.fetchNewPage(self.offset)
    }
    
    open func clearResults() {
        self.offset = 0
        self.ziphs = []
        self.totalPagesFetched = 0
    }
    
    fileprivate func fetchNewPage(_ offset:Int) -> CancelableTask? {
        
        if ziphsThisFetch == 0 && offset > 0 || offset == 0 && !ziphs.isEmpty {
            // no more results available
            return nil
        }
        
        return self.fetchBlock?(offset)
    }
    
    open func updatePagination(_ success:Bool, ziphs:[Ziph], error:Error?) {
        
        self.ziphsThisFetch = ziphs.count
        
        if (success) {
            
            self.totalPagesFetched += 1
            self.ziphs = self.ziphs + ziphs
            self.offset = self.ziphs.count
        }
        
        self.completionBlock?(success, self.ziphs, error)
    }
}
