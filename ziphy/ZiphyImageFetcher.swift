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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


private let giphyApiHost = "api.giphy.com"


public typealias SingleZiphCallBack = (_ imageData:Data?, _ ziph:Ziph?,  _ error:Error?) -> ()


@available(*, deprecated: 2.0)
@objc public class ZiphyImageFetcher: NSObject {
    
    open let term:String
    open let sizeLimit:Int
    open let resultsLimit:Int
    open let imageType:ZiphyImageType
    open let host:String
    
    fileprivate let ziphyClient:ZiphyClient
    
    fileprivate(set) open var ziphs:[Ziph]?
    
    fileprivate var iterationIndex = 0
    fileprivate var unsuccesfullIterations = 0
    fileprivate var gifsThisBatch = 0
    fileprivate var offset = 0
    fileprivate var usedIndexes = [Int]();
    
    
    public required init(term:String,
        sizeLimit:Int,
        resultslimit:Int = 25,
        imageType:ZiphyImageType,
        host:String = giphyApiHost,
        requester:ZiphyURLRequester) {
            
            self.host = host
            self.term = term
            self.imageType = imageType
            self.sizeLimit = sizeLimit
            self.resultsLimit = resultslimit
            
            self.ziphyClient = ZiphyClient(host:self.host, requester:requester)
    }
    
    
    open func nextImage(_ callBackQueue:DispatchQueue = DispatchQueue.main,
        onCompletion:@escaping SingleZiphCallBack) {
            
            switch self.term {
            case "":
                self.fetchGifFromRandom(callBackQueue,
                    onCompletion: onCompletion)
            default:
                self.fetchGifFromSearch(callBackQueue,
                    onCompletion: onCompletion)
            }
    }
    
    open func fetchNewBatch(_ currentBatch:[Ziph]?,
        callBackQueue:DispatchQueue = DispatchQueue.main,
        onCompletion:@escaping ZiphsCallBack) {
            
            let justZiphs = currentBatch ?? [Ziph]()
            
            self.offset = justZiphs.count
            
            _ = self.ziphyClient.search(callBackQueue,
                term: self.term,
                resultsLimit: self.resultsLimit,
                offset:self.offset) { (success, ziphs, error) in
                    
                    if(success){
                        
                        self.gifsThisBatch = ziphs.count
                        self.unsuccesfullIterations = 0;
                        self.ziphs = justZiphs + ziphs
                        
                        onCompletion(true, self.ziphs!, error)
                    }
                    else {
                        onCompletion(false, [Ziph](), error)
                    }
            }
    }
    
    fileprivate func fetchNewImage(_ callBackQueue:DispatchQueue, onCompletion:@escaping SingleZiphCallBack) {
        
        self.fetchNewBatch(self.ziphs, callBackQueue:callBackQueue) { (success, gifs, error) -> () in
            
            if (success) {
                self.nextImage(callBackQueue, onCompletion:onCompletion)
            }
            else {
                onCompletion(nil, nil, error)
            }
        }
    }
    
    fileprivate func fetchGifFromSearch(_ callBackQueue:DispatchQueue = DispatchQueue.main,
        onCompletion:@escaping SingleZiphCallBack) {
            
            if let justZiphs = self.ziphs {
                
                if self.iterationIndex > 0 && self.iterationIndex >= justZiphs.count {
                    
                    LogDebug("Reached result count \(justZiphs.count) starting at offset \(self.offset) for searchTerm \"\(self.term)\". Iteration \(self.iterationIndex) and result limit \(self.resultsLimit).")
                    
                    self.fetchNewImage(callBackQueue, onCompletion: onCompletion)
                    
                }
                else {
                    
                    if justZiphs.count > self.iterationIndex {
                        
                        LogVerbose("\(justZiphs.count) images avalable for term \(self.term) . Currently at index \(self.iterationIndex)")
                        
                        let randomNomalizedGenrator:() -> Int = {
                            let count = UInt32(justZiphs.count)
                            let randInt = Int(arc4random_uniform(count))
                            return randInt
                        }
                        
                        var ziph:Ziph? = nil
                        
                        if let newElement:Int = self.whileNotIn(self.usedIndexes, f: randomNomalizedGenrator) {
                            LogDebug("Appending element \(newElement) to \(self.usedIndexes)")
                            self.usedIndexes.append(newElement)
                            ziph = justZiphs[newElement]
                        }
                        else {
                            ziph = justZiphs[self.iterationIndex]
                        }
                        
                        let ziphyImage = ziph?.imageWithType(self.imageType)
                        
                        if ziphyImage?.size <= self.sizeLimit {
                            
                            self.ziphyClient.fetchImage(callBackQueue,
                                ziph:ziph!,
                                imageType:self.imageType,
                                onCompletion: { (success, image, ziph, data, error) -> () in
                                    
                                    if error == nil {
                                        
                                        onCompletion(data, ziph, nil)
                                    }
                                    else {
                                        onCompletion(nil, nil, error)
                                    }
                            })
                            
                            self.iterationIndex += 1
                            
                        }
                        else {
                            
                            self.unsuccesfullIterations += 1
                            
                            LogDebug("Image at iteration \(self.iterationIndex) didn't match size requirements")
                            LogDebug("Total images exceeding size requirements this batch \(self.unsuccesfullIterations)")
                            
                            self.iterationIndex += 1
                            if (unsuccesfullIterations == self.gifsThisBatch) {
                                
                                onCompletion(nil, nil, NSError(domain: ZiphyErrorDomain,
                                    code: ZiphyError.maxRetries.rawValue,
                                    userInfo:[NSLocalizedDescriptionKey:"The are no images in this batch that are of size \(self.sizeLimit). Giving up."]))
                            }
                            else {
                                self.nextImage(onCompletion:onCompletion)
                            }
                        }
                        
                    }
                    else {
                        
                        LogError("There are no more images for searchTerm \"\(self.term)\" at iteration \(self.iterationIndex) with resultslimit \(self.resultsLimit)")
                        
                        performOnQueue(callBackQueue) {
                            
                            onCompletion(nil, nil,
                                         NSError(domain: ZiphyErrorDomain,
                                    code: ZiphyError.noSuchResource.rawValue,
                                    userInfo:[NSLocalizedDescriptionKey:"No more images"]))
                        }
                    }
                }
            }
            else {
                
                LogDebug("First search for term \"\(self.term)\"")
                
                self.fetchNewImage(callBackQueue, onCompletion: onCompletion)
            }
    }
    
    
    fileprivate func fetchGifFromRandom(_ callBackQueue:DispatchQueue = DispatchQueue.main,
        onCompletion:@escaping (_ imageData:Data?, _ ziph:Ziph?,  _ error:Error?) -> ()) {
            
            self.tryFetchGifFromRandom(callBackQueue,
                iteration:0,
                giveUpAt: 3,
                onCompletion: onCompletion)
            
    }
    
    fileprivate func tryFetchGifFromRandom(_ callBackQueue:DispatchQueue = DispatchQueue.main,
        iteration:Int,
        giveUpAt:Int,
        onCompletion:@escaping (_ imageData:Data?, _ ziph:Ziph?,  _ error:Error?) -> ()) {
            
            if (iteration == giveUpAt) {
                performOnQueue(callBackQueue) {
                    onCompletion(nil, nil,
                                 NSError(domain: ZiphyErrorDomain,
                            code: ZiphyError.maxRetries.rawValue,
                            userInfo:[NSLocalizedDescriptionKey:"Attempted random fetch \(iteration) times, giving up."]))
                }
            }
            
            
            self.ziphyClient.randomGif(callBackQueue) { (success, gifId, error) -> () in
                
                if success && gifId != "" {
                    
                    self.ziphyClient.gifsById(callBackQueue,
                        ids: [gifId],
                        onCompletion: { (gifsByIdSuccess, ziphs, error) -> () in
                            
                            if gifsByIdSuccess && ziphs.count > 0 {
                                
                                let ziphsFilteredBySize = ziphs.filter { return $0.imageWithType(self.imageType)!.size <= self.sizeLimit }
                                
                                if ziphsFilteredBySize.count > 0 {
                                    
                                    let ziph:Ziph = ziphsFilteredBySize[0]
                                    
                                    self.ziphyClient.fetchImage(callBackQueue,
                                        ziph:ziph,
                                        imageType:self.imageType,
                                        onCompletion: { (success, image, ziph, data, error) -> () in
                                            
                                            if success && error == nil {
                                                
                                                onCompletion(data, ziph, nil)
                                            }
                                            else {
                                                onCompletion(nil, nil, error)
                                            }
                                    })
                                    
                                }
                                else {
                                    
                                    self.tryFetchGifFromRandom(callBackQueue, iteration:iteration, giveUpAt: giveUpAt, onCompletion: onCompletion)
                                }
                            }
                            else {
                                
                                onCompletion(nil, nil,
                                             NSError(domain: ZiphyErrorDomain,
                                        code: ZiphyError.noSuchResource.rawValue,
                                        userInfo:[NSLocalizedDescriptionKey:"Could not gifs with ids: \(gifId)"]))
                            }
                    })
                    
                }
                else {
                    
                    onCompletion(nil, nil,
                                 NSError(domain: ZiphyErrorDomain,
                            code: ZiphyError.badResponse.rawValue,
                            userInfo:[NSLocalizedDescriptionKey:"Could not get a random gif id"]))
                }
            }
    }
    
    
    fileprivate func whileNotIn<T: Comparable>(_ array:[T], f:@escaping ()->T) -> T? {
        
        var _whileNotIn:(_ array:[T], _ generator:()->T, _ index:Int) -> T? = { (_, gen, _) in  return gen()}
        
        _whileNotIn = { (array, generator, iterIndex) in
            
            LogVerbose("Gerating an element which should not be in \(array) at iteration \(iterIndex)")
            
            if iterIndex > array.count {
                return nil
            }
            else {
                var result:T? = f()
                if array.contains(result!) {
                    result = _whileNotIn(array, generator, iterIndex+1)
                }
                LogVerbose("Generated new element \(String(describing: result)) which is not in \(array) at iteration \(iterIndex)")
                return result
            }
        }
        
        return _whileNotIn(array, f, 0)
    }
}
