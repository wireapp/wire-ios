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

extension Array where Element:Ziph {
    fileprivate func filteredResults(maxImageSize: Int) -> [Ziph] {
        return self.filter({
            guard let size = $0.ziphyImages[ZiphyClient.fromZiphyImageTypeToString(.downsized)]?.size else { return false }
            return size < maxImageSize
        })
    }
}

final public class ZiphySearchResultsController {
    
    public var ziphyClient : ZiphyClient?

    public var resultsLastFetch:Int {
    
        return self.paginationController?.ziphsThisFetch ?? 0
    }
    
    public var totalPagesFetched:Int {
    
        return self.paginationController?.totalPagesFetched ?? 0
    }
    
    fileprivate var paginationController: ZiphyPaginationController?
    fileprivate (set) open var pageSize:Int
    fileprivate (set) open var maxImageSize:Int
    fileprivate let imageCache = NSCache<NSString, NSData>()
    fileprivate let callbackQueue : DispatchQueue
    
    
    public init(pageSize:Int, maxImageSize: Int = 1024 * 1024 * 3, callbackQueue:DispatchQueue = DispatchQueue.main) {
        
        self.callbackQueue = callbackQueue
        self.pageSize = pageSize
        self.maxImageSize = maxImageSize
        self.imageCache.totalCostLimit = 1024 * 1024 * 10 // 10MB
    }
    
    public func search(withSearchTerm searchTerm: String, _ completion:@escaping SuccessOrErrorCallback) -> CancelableTask? {
        
        self.paginationController = ZiphyPaginationController()
        self.paginationController?.fetchBlock = { [weak self] (offset) in
            
            if let strongSelf = self {
                
                return strongSelf.ziphyClient?.search(strongSelf.callbackQueue, term: searchTerm, resultsLimit: strongSelf.pageSize, offset: offset) { [weak self] (success, ziphs, error) -> () in
                    if let strongSelf = self {
                        strongSelf.updatePagination(success, ziphs, error)
                    }
                }
            }
            
            return nil
        }

        return fetchMoreResults(completion)
    }
    
    public func trending(_ completion:@escaping SuccessOrErrorCallback) -> CancelableTask? {
        self.paginationController = ZiphyPaginationController()
        self.paginationController?.fetchBlock = { [weak self] (offset) in
            
            if let strongSelf = self {
                
                return strongSelf.ziphyClient?.trending(strongSelf.callbackQueue, resultsLimit: strongSelf.pageSize, offset: offset) { [weak self] (success, ziphs, error) in
                    if let strongSelf = self {
                        strongSelf.updatePagination(success, ziphs, error)
                    }
                }
            }
            
            return nil
        }
        
        return fetchMoreResults(completion)
    }

    func updatePagination(_ success:Bool, _ ziphs:[Ziph], _ error:Error?) {
        paginationController?.updatePagination(success, ziphs: ziphs.filteredResults(maxImageSize: maxImageSize), error: error)
    }

    public func fetchMoreResults(_ completion:@escaping SuccessOrErrorCallback) -> CancelableTask? {
        self.paginationController?.completionBlock = completion
        return self.paginationController?.fetchNewPage()
    }
    
    public func fetchImageData(forZiph ziph: Ziph, imageType: ZiphyImageType, completion: @escaping (_ imageData: Data?, _ imageRepresentation: ZiphyImageRep?, _ error: Error?) -> Void) {
        let representation = ziph.ziphyImages[ZiphyClient.fromZiphyImageTypeToString(imageType)]!

        if let imageData = self.imageCache.object(forKey: representation.url as NSString) {
            completion(imageData as Data, representation, nil)
        }
        
        self.ziphyClient?.fetchImage(DispatchQueue.main, ziph: ziph, imageType: imageType, onCompletion: { [weak self] (success, imageRepresentation, ziph, imageData, error) in
            if error == nil, let imageData = imageData, let imageRepresentation = imageRepresentation {
                self?.imageCache.setObject(imageData as NSData, forKey: imageRepresentation.url as NSString)
                completion(imageData, imageRepresentation, nil)
            } else {
                completion(nil, nil, error)
            }
        })
    }
}
