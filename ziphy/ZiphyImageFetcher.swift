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

private let giphyApiHost = "api.giphy.com"


public typealias SingleZiphCallBack = (imageData:NSData?, ziph:Ziph?,  error:NSError?) -> ()


@available(*, deprecated=2.0)
@objc public class ZiphyImageFetcher: NSObject {
    
    public let term:String
    public let sizeLimit:Int
    public let resultsLimit:Int
    public let imageType:ZiphyImageType
    public let host:String
    
    private let ziphyClient:ZiphyClient
    
    private(set) public var ziphs:[Ziph]?
    
    private var iterationIndex = 0
    private var unsuccesfullIterations = 0
    private var gifsThisBatch = 0
    private var offset = 0
    private var usedIndexes = [Int]();
    
    
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
    
    
    public func nextImage(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        onCompletion:SingleZiphCallBack) {
            
            switch self.term {
            case "":
                self.fetchGifFromRandom(callBackQueue,
                    onCompletion: onCompletion)
            default:
                self.fetchGifFromSearch(callBackQueue,
                    onCompletion: onCompletion)
            }
    }
    
    public func fetchNewBatch(currentBatch:[Ziph]?,
        callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        onCompletion:ZiphsCallBack) {
            
            let justZiphs = currentBatch ?? [Ziph]()
            
            self.offset = justZiphs.count
            
            self.ziphyClient.search(callBackQueue,
                term: self.term,
                resultsLimit: self.resultsLimit,
                offset:self.offset) { (success, ziphs, error) in
                    
                    if(success){
                        
                        self.gifsThisBatch = ziphs.count
                        self.unsuccesfullIterations = 0;
                        self.ziphs = justZiphs + ziphs
                        
                        onCompletion(success: true, ziphs:self.ziphs!, error: error)
                    }
                    else {
                        onCompletion(success: false, ziphs:[Ziph](), error: error)
                    }
            }
    }
    
    private func fetchNewImage(callBackQueue:dispatch_queue_t, onCompletion:SingleZiphCallBack) {
        
        self.fetchNewBatch(self.ziphs, callBackQueue:callBackQueue) { (success, gifs, error) -> () in
            
            if (success) {
                self.nextImage(callBackQueue, onCompletion:onCompletion)
            }
            else {
                onCompletion(imageData: nil, ziph: nil, error: error)
            }
        }
    }
    
    private func fetchGifFromSearch(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        onCompletion:SingleZiphCallBack) {
            
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
                                        
                                        onCompletion(imageData:data, ziph:ziph, error: nil)
                                    }
                                    else {
                                        onCompletion(imageData: nil, ziph:nil, error:error)
                                    }
                            })
                            
                            self.iterationIndex++
                            
                        }
                        else {
                            
                            self.unsuccesfullIterations++
                            
                            LogDebug("Image at iteration \(self.iterationIndex) didn't match size requirements")
                            LogDebug("Total images exceeding size requirements this batch \(self.unsuccesfullIterations)")
                            
                            self.iterationIndex++
                            if (unsuccesfullIterations == self.gifsThisBatch) {
                                
                                onCompletion(imageData: nil, ziph: nil, error:NSError(domain: ZiphyErrorDomain,
                                    code: ZiphyError.MaxRetries.rawValue,
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
                            
                            onCompletion(imageData: nil, ziph:nil,
                                error:NSError(domain: ZiphyErrorDomain,
                                    code: ZiphyError.NoSuchResource.rawValue,
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
    
    
    private func fetchGifFromRandom(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        onCompletion:(imageData:NSData?, ziph:Ziph?,  error:NSError?) -> ()) {
            
            self.tryFetchGifFromRandom(callBackQueue,
                iteration:0,
                giveUpAt: 3,
                onCompletion: onCompletion)
            
    }
    
    private func tryFetchGifFromRandom(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        iteration:Int,
        giveUpAt:Int,
        onCompletion:(imageData:NSData?, ziph:Ziph?,  error:NSError?) -> ()) {
            
            if (iteration == giveUpAt) {
                performOnQueue(callBackQueue) {
                    onCompletion(imageData: nil, ziph:nil,
                        error:NSError(domain: ZiphyErrorDomain,
                            code: ZiphyError.MaxRetries.rawValue,
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
                                                
                                                onCompletion(imageData:data, ziph:ziph, error: nil)
                                            }
                                            else {
                                                onCompletion(imageData: nil, ziph:nil, error:error)
                                            }
                                    })
                                    
                                }
                                else {
                                    
                                    self.tryFetchGifFromRandom(callBackQueue, iteration:iteration, giveUpAt: giveUpAt, onCompletion: onCompletion)
                                }
                            }
                            else {
                                
                                onCompletion(imageData: nil, ziph:nil,
                                    error:NSError(domain: ZiphyErrorDomain,
                                        code: ZiphyError.NoSuchResource.rawValue,
                                        userInfo:[NSLocalizedDescriptionKey:"Could not gifs with ids: \(gifId)"]))
                            }
                    })
                    
                }
                else {
                    
                    onCompletion(imageData: nil, ziph:nil,
                        error:NSError(domain: ZiphyErrorDomain,
                            code: ZiphyError.BadResponse.rawValue,
                            userInfo:[NSLocalizedDescriptionKey:"Could not get a random gif id"]))
                }
            }
    }
    
    
    private func whileNotIn<T: Comparable>(array:[T], f:()->T) -> T? {
        
        var _whileNotIn:(array:[T], generator:()->T, index:Int) -> T? = { (_, gen, _) in  return gen()}
        
        _whileNotIn = { (array, generator, iterIndex) in
            
            LogVerbose("Gerating an element which should not be in \(array) at iteration \(iterIndex)")
            
            if iterIndex > array.count {
                return nil
            }
            else {
                var result:T? = f()
                if array.contains(result!) {
                    result = _whileNotIn(array: array, generator: generator, index: iterIndex+1)
                }
                LogVerbose("Generated new element \(result) which is not in \(array) at iteration \(iterIndex)")
                return result
            }
        }
        
        return _whileNotIn(array: array, generator: f, index: 0)
    }
}
