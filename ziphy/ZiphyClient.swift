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
private let searchEndpoint = gifsEndpoint.stringByAppendingString("/search")
private let randomEndpoint = gifsEndpoint.stringByAppendingString("/random")
private let requestScheme = "https"



public typealias ZiphsCallBack = (success:Bool, ziphs:[Ziph], error:NSError?) -> ()
public typealias ZiphByIdCallBack = (success:Bool, ziphId:String, error:NSError?)->()
public typealias ZiphyImageCallBack = (success:Bool, image:ZiphyImageRep?, ziph:Ziph, data:NSData?, error:NSError?) -> ()

@objc public class ZiphyClient : NSObject {
    
    
    public static var logLevel:ZiphyLogLevel = ZiphyLogLevel.Error
    let host:String
    let requester:ZiphyURLRequester
    let downloadSession:NSURLSession
    let requestGenerator:ZiphyRequestGenerator
    
    public required init(host:String, requester: ZiphyURLRequester) {
        
        self.requester = requester
        self.host = host
        self.downloadSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        self.requestGenerator = ZiphyRequestGenerator(host:self.host,
            requestScheme:requestScheme,
            apiVersionPath:apiVersionPath,
            searchEndpoint:searchEndpoint,
            randomEndpoint:randomEndpoint,
            gifsEndpoint:gifsEndpoint)
    }
    
    public func search(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        term:String,
        resultsLimit:Int = 25,
        offset:Int = 0,
        onCompletion:ZiphsCallBack) {
            
            switch self.requestGenerator.searchRequestWithParameters(term, resultsLimit:resultsLimit, offset:offset) {
                
            case .Left(let box):
                performOnQueue(callBackQueue) {
                    onCompletion(success: false, ziphs:[Ziph](), error: box.value)
                }
            case .Right(let box):
                
                self.performDataTask(box.value, requester:self.requester).then { (data, _, nError) in
                    
                    switch self.checkDataForPagination(data, resultsLimit:resultsLimit, offset:offset) {
                        
                    case .Left(let box):
                        return box.value
                    case .Right(_):
                        return nil
                    }
                    
                    }.then { (data, _, nError) in
                        
                        switch self.checkDataForImageArray(data) {
                            
                        case .Left(let box):
                            return box.value
                        case .Right(let box):
                            performOnQueue(callBackQueue) {
                                onCompletion(success: true, ziphs:box.value, error:nil)
                            }
                            return nil
                        }
                        
                    }.fail{ (error) -> () in
                        
                        performOnQueue(callBackQueue) {
                            onCompletion(success:false, ziphs:[Ziph](), error:error)
                        }
                }
            }
    }
    
    public func randomGif(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        onCompletion:ZiphByIdCallBack) {
            
            switch self.requestGenerator.randomRequests() {
            case .Left(let box):
                performOnQueue(callBackQueue) {
                    onCompletion(success: false, ziphId:"", error: box.value)
                }
            case .Right(let box):
                self.performDataTask(box.value, requester:self.requester).then({ (data, response, error) -> NSError? in
                    
                    switch self.checkDataForGifId(data) {
                    case .Left(let box):
                        return box.value
                    case .Right(let box):
                        performOnQueue(callBackQueue) {
                            onCompletion(success: true, ziphId:box.value, error:nil)
                        }
                        return nil
                    }
                    
                }).fail({ (error) -> () in
                    performOnQueue(callBackQueue) {
                        onCompletion(success:false, ziphId:"", error:error)
                    }
                })
            }
    }
    
    public func gifsById(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        ids:[String],
        onCompletion:ZiphsCallBack) {
            
            switch self.requestGenerator.gifsByIdRequest(ids) {
                
            case .Left(let box):
                performOnQueue(callBackQueue) {
                    onCompletion(success: false, ziphs:[Ziph](), error: box.value)
                }
            case .Right(let box):
                
                self.performDataTask(box.value, requester:self.requester).then { (data, _, nError) in
                    
                    switch self.checkDataForImageArray(data) {
                        
                    case .Left(let box):
                        return box.value
                    case .Right(let box):
                        performOnQueue(callBackQueue) {
                            onCompletion(success: true, ziphs:box.value, error:nil)
                        }
                        return nil
                    }
                    
                    }.fail{ (error) -> () in
                        
                        performOnQueue(callBackQueue) {
                            onCompletion(success:false, ziphs:[Ziph](), error:error)
                        }
                }
            }
            
    }
    
    public func fetchImage(callBackQueue:dispatch_queue_t = dispatch_get_main_queue(),
        ziph:Ziph,
        imageType:ZiphyImageType,
        onCompletion:ZiphyImageCallBack) {
            
            if let ziphyImage = ziph.imageWithType(imageType) {
                
                LogDebug("Trying to fetch image at url \(ziphyImage.url)")
                
                if let components = NSURLComponents(string:ziphyImage.url) {
                    
                    if let url = components.URL {
                        
                        let request = NSURLRequest(URL:url)
                        
                        self.performDataTask(request, requester:self.downloadSession).then { (data, response, error) -> NSError? in
                            LogDebug("Fetch of image at url \(ziphyImage.url) succeeded")
                            
                            performOnQueue(callBackQueue) {
                                onCompletion(success: true, image:ziphyImage, ziph:ziph, data: data, error: error)
                            }
                            return nil
                            }.fail({ (error) -> () in
                                LogError("Fetch of image \(ziphyImage) failed")
                                performOnQueue(callBackQueue) {
                                    onCompletion(success: false, image:ziphyImage, ziph:ziph, data:nil, error: error)
                                }
                            })
                    }
                }
            }
            else {
                
                LogError("Ziphy asked to fetch image of type \(imageType), but no such type exists in \(ziph)")
                performOnQueue(callBackQueue){
                    let userInfo = [NSLocalizedDescriptionKey:"No type \(imageType) in ziph: \(ziph)"]
                    let error = NSError(domain: ZiphyErrorDomain, code: ZiphyError.NoSuchResource.rawValue, userInfo:userInfo)
                    onCompletion(success: false, image:nil, ziph:ziph, data:nil, error: error)
                }
            }
            
            
            
    }
    
    private func performDataTask(request:NSURLRequest, requester:ZiphyURLRequester) -> NSURLRequestPromise {
        
        let promise = NSURLRequestPromise()
        
        requester.doRequest(request){ (data, response, nError) -> Void in
            
            if let error = nError {
                promise.reject(error)
            }
            
            promise.resolve()(data: data, response: response, error: nError)
        }
        
        return promise
    }
    
    private func checkDataForPagination(data:NSData!, resultsLimit:Int, offset:Int)->Either<NSError, AnyObject> {
        
        if data == nil {
            
            return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.BadResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"No data in network response"])))
        }
        
        do {
            let maybeResponse = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String:AnyObject]
            
            if let paginationInfo = maybeResponse?["pagination"] as? [String:AnyObject] {
                
                LogDebug("Pagination Info: \(paginationInfo)")
                
                if let _ = paginationInfo["count"] as? Int,
                    let total_count = paginationInfo["total_count"] as? Int,
                    let offset = paginationInfo["offset"] as? Int {
                        
                        if offset >= total_count {
                            
                            return  Either.Left(Box(value: NSError(domain: ZiphyErrorDomain,
                                code:ZiphyError.NoMorePages.rawValue,
                                userInfo:[NSLocalizedDescriptionKey:"No more pages in JSON"])))
                        }
                }
            }
            else{
                
                return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                    code:ZiphyError.BadResponse.rawValue,
                    userInfo:[NSLocalizedDescriptionKey:"Pagination error in JSON"])))
            }
        } catch (let error as NSError) {
            LogError(error.localizedDescription)
            return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.BadResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"JSON Serialization error", NSUnderlyingErrorKey: error])))
        }
        
        
        return Either.Right(Box(value:[]))
    }
    
    private func checkDataForImageArray(data:NSData!) -> Either<NSError,[Ziph]> {
        
        if data == nil {
            
            return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.BadResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"No data in network response"])))
        }
        
        do {
            let maybeResponse = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String:AnyObject]
            
            if let gifsArray = maybeResponse?["data"] as? [[String:AnyObject]] {
                
                let fromSearchResultToZiph = { (aGif:[String:AnyObject]) -> Ziph? in
                    
                    Ziph(dictionary: aGif)
                }
                
                let arrayOfPossibleZiphs = gifsArray.filter { return fromSearchResultToZiph($0) != nil }
                let ziphs = arrayOfPossibleZiphs.map { return Ziph(dictionary:$0)! }
                
                return Either.Right(Box(value: ziphs))
            }
            else {
                
                LogError("Response Error: \(maybeResponse)")
                
                return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                    code:ZiphyError.BadResponse.rawValue,
                    userInfo:[NSLocalizedDescriptionKey:"Data field missing in JSON"])))
            }
        } catch (let error as NSError) {
            LogError(error.localizedDescription)
            return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.BadResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"JSON Serialization error", NSUnderlyingErrorKey: error])))
        }
    }
    
    private func checkDataForGifId(data:NSData!) -> Either<NSError,String> {
        
        if data == nil {
            
            return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.BadResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"No data in network response"])))
        }
        do {
            let maybeResponse = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String:AnyObject]
            if let randomGifDesc = maybeResponse?["data"] as? [String:AnyObject] {
                
                let gifId:String? = randomGifDesc["id"] as? String
                return Either.Right(Box(value: gifId ?? ""))
            }
            else {
                
                LogError("Response Error: \(maybeResponse)")
                
                return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                    code:ZiphyError.BadResponse.rawValue,
                    userInfo:[NSLocalizedDescriptionKey:"Data field missing in JSON"])))
            }
        } catch (let error as NSError) {
            LogError(error.localizedDescription)
            return Either.Left(Box(value:NSError(domain: ZiphyErrorDomain,
                code:ZiphyError.BadResponse.rawValue,
                userInfo:[NSLocalizedDescriptionKey:"JSON Serialization error", NSUnderlyingErrorKey: error])))
        }
        
    }
}

extension ZiphyClient {
    
    public class func fromZiphyImageTypeToString(type:ZiphyImageType) -> String
    {
        switch type {
        case .FixedHeight: return "fixed_height"
        case .FixedHeightStill: return "fixed_height_still"
        case .FixedHeightDownsampled: return "fixed_height_downsampled"
        case .FixedWidth: return "fixed_width"
        case .FixedWidthStill: return "fixed_width_still"
        case .FixedWidthDownsampled: return "fixed_width_downsampled"
        case .FixedHeightSmall: return "fixed_height_small"
        case .FixedHeightSmallStill: return "fixed_height_small_still"
        case .FixedWidthSmall: return "fixed_width_small"
        case .FixedWidthSmallStill: return "fixed_width_small_still"
        case .Downsized: return "downsized"
        case .DownsizedStill: return "downsized_still"
        case .DownsizedLarge: return "downsized_large"
        case .Original: return "original"
        case .OriginalStill: return "original_still"
        default: return "unkwnown"
        }
    }
    
    public class func fromStringToZiphyImageType(string:String) -> ZiphyImageType
    {
        switch string {
        case "fixed_height": return .FixedHeight
        case "fixed_height_still": return .FixedHeightStill
        case "fixed_height_downsampled": return .FixedHeightDownsampled
        case "fixed_width": return .FixedWidth
        case "fixed_width_still": return .FixedWidthStill
        case "fixed_width_downsampled": return .FixedWidthDownsampled
        case "fixed_height_small": return .FixedHeightSmall
        case "fixed_height_small_still": return .FixedHeightSmallStill
        case "fixed_width_small": return .FixedWidthSmall
        case "fixed_width_small_still": return .FixedWidthSmallStill
        case "downsized": return .Downsized
        case "downsized_still": return .DownsizedStill
        case "downsized_large": return .DownsizedLarge
        case "original": return .Original
        case "original_still": return .OriginalStill
        default: return .Unknown
        }
    }
}
