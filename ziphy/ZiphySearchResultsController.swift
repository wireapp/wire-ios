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



@objc public class ZiphySearchResultsController : NSObject {
    
    
    open var ziphyClient:ZiphyClient?
    open let searchTerm:String
    
    open var results:[Ziph]? {
        
        return self.paginationController.ziphs
    }

    open var resultsLastFetch:Int {
    
        return self.paginationController.ziphsThisFetch
    }
    
    open var totalPagesFetched:Int {
    
        return self.paginationController.totalPagesFetched
    }
    
    fileprivate let paginationController:ZiphyPaginationController
    fileprivate (set) open var pageSize:Int
    
    
    public init(searchTerm:String,
        pageSize:Int,
        callBackQueue:DispatchQueue = DispatchQueue.main) {
            
            self.searchTerm = searchTerm
            self.pageSize = pageSize
            self.paginationController = ZiphyPaginationController(callBackQueue:callBackQueue)
            
            super.init()
            
            self.paginationController.fetchBlock = { [weak self](offSet) in
                
                if let strongSelf = self {
                    
                    strongSelf.ziphyClient?.search(callBackQueue,
                        term: strongSelf.searchTerm,
                        resultsLimit: strongSelf.pageSize,
                        offset: offSet) { [weak self](success, ziphs, error) -> () in
                            if let strongSelf = self {
                                strongSelf.paginationController.updatePagination(success, ziphs: ziphs, error: error)
                            }
                    }
                }
            }
    }
    
    open func fetchSearchResults(_ completion:@escaping SuccessOrErrorCallback) {
        
        self.paginationController.completionBlock = completion
        self.paginationController.fetchNewPage()
    }
}
