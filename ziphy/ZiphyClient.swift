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

private let apiVersionPath = "/v1"
private let gifsEndpoint = "/gifs"
private let searchEndpoint = gifsEndpoint + "/search"
private let randomEndpoint = gifsEndpoint + "/random"
private let trendingEndpoint = gifsEndpoint + "/trending"
private let requestScheme = "https"

public typealias ZiphsCallBack = (_ success:Bool, _ ziphs:[Ziph], _ error:Error?) -> ()
public typealias ZiphByIdCallBack = (_ success:Bool, _ ziphId:String, _ error:Error?)->()
public typealias ZiphyImageCallBack = (_ success:Bool, _ image:ZiphyImageRep?, _ ziph:Ziph, _ data:Data?, _ error:Error?) -> ()

@objcMembers public final class ZiphyClient: NSObject {
    
    open static var logLevel: ZiphyLogLevel = .error
    let host:String
    let requester:ZiphyURLRequester
    let downloadSession:URLSession
    let requestGenerator:ZiphyRequestGenerator
    
    public required init(host:String, requester: ZiphyURLRequester) {
        self.requester = requester
        self.host = host
        self.downloadSession = URLSession(configuration: URLSessionConfiguration.default)
        self.requestGenerator = ZiphyRequestGenerator(host:self.host,
            requestScheme:requestScheme,
            apiVersionPath:apiVersionPath,
            searchEndpoint:searchEndpoint,
            randomEndpoint:randomEndpoint,
            trendingEndpoint:trendingEndpoint,
            gifsEndpoint:gifsEndpoint)
    }
    
    public func trending(_ callBackQueue:DispatchQueue = DispatchQueue.main, resultsLimit:Int = 25, offset:Int, onCompletion: @escaping ZiphsCallBack) -> CancelableTask? {
        
        let eitherRequest = self.requestGenerator.trendingRequestWithParameters(resultsLimit: resultsLimit, offset: offset)
        return  performZiphListRequest(eitherRequest: eitherRequest, onCompletion: onCompletion, callBackQueue: callBackQueue)
    }
    
    public func search(_ callBackQueue:DispatchQueue = DispatchQueue.main, term:String, resultsLimit:Int = 25, offset:Int = 0, onCompletion: @escaping ZiphsCallBack) -> CancelableTask? {
        
        let eitherRequest = self.requestGenerator.searchRequestWithParameters(term, resultsLimit:resultsLimit, offset:offset)
        return performZiphListRequest(eitherRequest: eitherRequest, onCompletion: onCompletion, callBackQueue: callBackQueue)
    }
    
    func performZiphListRequest(eitherRequest: Either<Error, URLRequest>, onCompletion: @escaping ZiphsCallBack, callBackQueue : DispatchQueue) -> CancelableTask? {
        var searchTask : CancelableTask? = nil
        
        eitherRequest.leftMap { error in
            
            performOnQueue(callBackQueue) {
                onCompletion(false, [Ziph](), error)
            }
        }
        
        eitherRequest.rightMap { urlRequest in
            
            searchTask = self.performDataTask(urlRequest, requester:self.requester).then { (data, _, nError) in
                
                let eitherPaginationData = self.checkDataForPagination(data)
                
                return eitherPaginationData.left
                
                }.then { (data, _, nError) in
                    
                    let eitherImageArray = self.checkDataForImageArray(data)
                    
                    return eitherImageArray.rightMap { ziphs in
                        
                        performOnQueue(callBackQueue) {
                            onCompletion(true, ziphs, nil)
                        }
                        
                        }.left
                    
                }.fail { error in
                    
                    performOnQueue(callBackQueue) {
                        onCompletion(false, [Ziph](), error)
                    }
            }
        }
        
        return searchTask
    }
    
    public func randomGif(_ callBackQueue:DispatchQueue = DispatchQueue.main,
        onCompletion:@escaping ZiphByIdCallBack) {
        
        let eitherRequest = self.requestGenerator.randomRequests()
        
        eitherRequest.leftMap { error in
            
            performOnQueue(callBackQueue) {
                onCompletion(false, "", error)
            }
        }
        
        eitherRequest.rightMap { request in
            
            self.performDataTask(request, requester:self.requester).then { (data, response, error) -> Error? in
                
                let eitherGifID = self.checkDataForGifId(data)
                
                return eitherGifID.rightMap { ziphId in
                    
                    performOnQueue(callBackQueue) {
                        onCompletion(true, ziphId, nil)
                    }
                }.left
                
            }.fail { error in
                performOnQueue(callBackQueue) {
                    onCompletion(false, "", error)
                }
            }
        }
    }
    
    public func gifsById(_ callBackQueue:DispatchQueue = DispatchQueue.main,
        ids:[String],
        onCompletion:@escaping ZiphsCallBack) {
        
        let eitherRequest = self.requestGenerator.gifsByIdRequest(ids)
        
        eitherRequest.leftMap { error in
            
            performOnQueue(callBackQueue) {
                onCompletion(false, [Ziph](), error)
            }
        }
        
        eitherRequest.rightMap { request in
            
            self.performDataTask(request, requester:self.requester).then { (data, _, nError) in
                
                let eitherImageArray = self.checkDataForImageArray(data)
                
                return eitherImageArray.rightMap { ziphs in
                    
                    performOnQueue(callBackQueue) {
                        onCompletion(true, ziphs, nil)
                    }
                }.left
                
            }.fail { error in
                    
                performOnQueue(callBackQueue) {
                    onCompletion(false, [Ziph](), error)
                }
            }
        }
        
    }
    
    public func fetchImage(_ callBackQueue:DispatchQueue = DispatchQueue.main,
        ziph:Ziph,
        imageType:ZiphyImageType,
        onCompletion:@escaping ZiphyImageCallBack) {
            
            if let ziphyImage = ziph.imageWithType(imageType) {
                
                LogDebug("Trying to fetch image at url \(ziphyImage.url)")
                
                if let components = URLComponents(string:ziphyImage.url) {
                    
                    if let url = components.url {
                        
                        let request = URLRequest(url:url)
                        
                        self.performDataTask(request, requester:self.downloadSession).then { (data, response, error) -> Error? in
                            LogDebug("Fetch of image at url \(ziphyImage.url) succeeded")
                            
                            performOnQueue(callBackQueue) {
                                onCompletion(true, ziphyImage, ziph, data, error)
                            }
                            return nil
                            }.fail({ (error) -> () in
                                LogError("Fetch of image \(ziphyImage) failed")
                                performOnQueue(callBackQueue) {
                                    onCompletion(false, ziphyImage, ziph, nil, error)
                                }
                            })
                    }
                }
            }
            else {
                
                LogError("Ziphy asked to fetch image of type \(imageType), but no such type exists in \(ziph)")
                performOnQueue(callBackQueue){
                    let userInfo = [NSLocalizedDescriptionKey:"No type \(imageType) in ziph: \(ziph)"]
                    let error = NSError(domain: ZiphyErrorDomain, code: ZiphyError.noSuchResource.rawValue, userInfo:userInfo)
                    onCompletion(false, nil, ziph, nil, error)
                }
            }
            
            
            
    }
    
    fileprivate func performDataTask(_ request:URLRequest, requester:ZiphyURLRequester) -> URLRequestPromise {
        
        let promise = URLRequestPromise(requester: requester)
        
        let requestIdentifier = requester.doRequest(request) { (data, response, nError) -> Void in
            
            if let error = nError {
                promise.reject(error)
            }
            
            promise.resolve()(data, response, nError)
        }
        
        promise.requestIdentifier = requestIdentifier
        
        return promise
    }
    
    fileprivate func checkDataForPagination(_ data:Data!)->Either<Error, AnyObject> {
        
        if data == nil {
            return .left(NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.badResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"No data in network response"]))
        }
        
        do {
            let maybeResponse = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject]
            
            if let paginationInfo = maybeResponse?["pagination"] as? [String:AnyObject] {
                
                LogDebug("Pagination Info: \(paginationInfo)")
                
                if let _ = paginationInfo["count"] as? Int,
                    let total_count = paginationInfo["total_count"] as? Int,
                    let offset = paginationInfo["offset"] as? Int {
                        
                        if offset >= total_count {
                            return  .left(NSError(domain: ZiphyErrorDomain,
                                code: ZiphyError.noMorePages.rawValue,
                                userInfo: [NSLocalizedDescriptionKey:"No more pages in JSON"]))
                        }
                }
            }
            else {
                return .left((NSError(domain: ZiphyErrorDomain,
                    code:ZiphyError.badResponse.rawValue,
                    userInfo:[NSLocalizedDescriptionKey:"Pagination error in JSON"])))
            }
        } catch (let error as NSError) {
            LogError(error.localizedDescription)
            return .left(NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.badResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"JSON Serialization error", NSUnderlyingErrorKey: error]))
        }
        
        
        return .right([] as AnyObject)
    }
    
    fileprivate func checkDataForImageArray(_ data:Data!) -> Either<Error,[Ziph]> {
        
        if data == nil {
            return .left(NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.badResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"No data in network response"]))
        }
        
        do {
            let maybeResponse = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject]
            
            if let gifsArray = maybeResponse?["data"] as? [[String:AnyObject]] {
                
                let fromSearchResultToZiph = { (aGif:[String:AnyObject]) -> Ziph? in
                    
                    Ziph(dictionary: aGif)
                }
                
                let arrayOfPossibleZiphs = gifsArray.filter { return fromSearchResultToZiph($0) != nil }
                let ziphs = arrayOfPossibleZiphs.map { return Ziph(dictionary:$0)! }
                
                return .right(ziphs)
            }
            else {
                
                LogError("Response Error: \(String(describing: maybeResponse))")
                
                return .left(NSError(domain: ZiphyErrorDomain,
                    code:ZiphyError.badResponse.rawValue,
                    userInfo:[NSLocalizedDescriptionKey:"Data field missing in JSON"]))
            }
        } catch (let error as NSError) {
            LogError(error.localizedDescription)
            return .left(NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.badResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"JSON Serialization error", NSUnderlyingErrorKey: error]))
        }
    }
    
    fileprivate func checkDataForGifId(_ data:Data!) -> Either<NSError,String> {
        
        if data == nil {
            
            return .left(NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.badResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"No data in network response"]))
        }
        do {
            let maybeResponse = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject]
            if let randomGifDesc = maybeResponse?["data"] as? [String:AnyObject] {
                
                let gifId:String? = randomGifDesc["id"] as? String
                return .right(gifId ?? "")
            }
            else {
                
                LogError("Response Error: \(String(describing: maybeResponse))")
                
                return .left(NSError(domain: ZiphyErrorDomain,
                    code:ZiphyError.badResponse.rawValue,
                    userInfo:[NSLocalizedDescriptionKey:"Data field missing in JSON"]))
            }
        } catch (let error as NSError) {
            LogError(error.localizedDescription)
            return .left(NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.badResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"JSON Serialization error", NSUnderlyingErrorKey: error]))
        }
        
    }
}

@objc extension ZiphyClient {
    
    public class func fromZiphyImageTypeToString(_ type:ZiphyImageType) -> String
    {
        switch type {
        case .fixedHeight: return "fixed_height"
        case .fixedHeightStill: return "fixed_height_still"
        case .fixedHeightDownsampled: return "fixed_height_downsampled"
        case .fixedWidth: return "fixed_width"
        case .fixedWidthStill: return "fixed_width_still"
        case .fixedWidthDownsampled: return "fixed_width_downsampled"
        case .fixedHeightSmall: return "fixed_height_small"
        case .fixedHeightSmallStill: return "fixed_height_small_still"
        case .fixedWidthSmall: return "fixed_width_small"
        case .fixedWidthSmallStill: return "fixed_width_small_still"
        case .downsized: return "downsized"
        case .downsizedStill: return "downsized_still"
        case .downsizedLarge: return "downsized_large"
        case .original: return "original"
        case .originalStill: return "original_still"
        default: return "unkwnown"
        }
    }
    
    public class func fromStringToZiphyImageType(_ string:String) -> ZiphyImageType
    {
        switch string {
        case "fixed_height": return .fixedHeight
        case "fixed_height_still": return .fixedHeightStill
        case "fixed_height_downsampled": return .fixedHeightDownsampled
        case "fixed_width": return .fixedWidth
        case "fixed_width_still": return .fixedWidthStill
        case "fixed_width_downsampled": return .fixedWidthDownsampled
        case "fixed_height_small": return .fixedHeightSmall
        case "fixed_height_small_still": return .fixedHeightSmallStill
        case "fixed_width_small": return .fixedWidthSmall
        case "fixed_width_small_still": return .fixedWidthSmallStill
        case "downsized": return .downsized
        case "downsized_still": return .downsizedStill
        case "downsized_large": return .downsizedLarge
        case "original": return .original
        case "original_still": return .originalStill
        default: return .unknown
        }
    }
}
