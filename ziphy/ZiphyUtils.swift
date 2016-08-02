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



func performOnQueue(callBackQueue:dispatch_queue_t, a:()->() ){
    
    dispatch_async(callBackQueue, a)
}

enum Either<L, R> {
    
    case Left(L)
    case Right(R)
    
    var isLeft: Bool {
        
        switch self {
        case Left:
            return true
        case .Right:
            return false
        }
    }
    
    var isRight: Bool {
        
        switch self {
        case Right:
            return true
        case .Left:
            return false
        }
    }
    
    var right: R? {
    
        switch self {
        case let Right(r):
            return r
        case .Left:
            return nil
        }
        
    }
    
    var left: L? {
        
        switch self {
        case let Left(l):
            return l
        case .Right:
            return nil
        }
    }
    
    func bimap<B, D>(f : L -> B, _ g : (R -> D)) -> Either<B, D> {
        
        switch self {
        case let .Left(bx):
            return Either<B, D>.Left(f(bx))
        case let .Right(bx):
            return Either<B, D>.Right(g(bx))
        }
    }
    
    
    func leftMap<B>(f : L -> B) -> Either<B, R> {
        return self.bimap(f, identity)
    }
    
    func rightMap<D>(g : R -> D) -> Either<L, D> {
        return self.bimap(identity, g)
    }
    
    func identity<A>(a: A) -> A {
        return a
    }

}

typealias NSURLRequestCallBack = (data:NSData?, response:NSURLResponse?, error:NSError?)->NSError?

class NSURLRequestPromise {
    
    var pending: [NSURLRequestCallBack] = []
    var onFailure: (error: NSError) -> () = { error in return }
    var failure: NSError? = nil
    
    func resolve() -> NSURLRequestCallBack {
        
        func performAResolution(data:NSData?, response:NSURLResponse?, error:NSError?) -> NSError? {
            
            if error != nil {
                
                onFailure(error: error!)
                return nil
            }
            
            for f in self.pending {
                
                self.failure = f(data: data, response: response, error: error)
                
                if let error = self.failure {
                    
                    onFailure(error: error)
                    break
                }
            }
            
            return nil
        }
        
        return performAResolution
    }
    
    func fail(onFailure: (error: NSError) ->() ) -> NSURLRequestPromise {
        
        self.onFailure = onFailure
        return self
    }
    
    func reject(error:NSError) {
        
        self.failure = error
    }
    
    func then(what: NSURLRequestCallBack) -> NSURLRequestPromise {
        
        self.pending.append(what)
        return self
    }
}

@objc public protocol ZiphyURLRequester {
    
    func doRequest(request :NSURLRequest, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void))
}

extension NSURLSession : ZiphyURLRequester {
    
    public func doRequest(request :NSURLRequest, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        self.dataTaskWithRequest(request, completionHandler: completionHandler).resume()
    }
}

@objc public enum ZiphyImageType:Int {
    
    case FixedHeight
    case FixedHeightStill
    case FixedHeightDownsampled
    case FixedWidth
    case FixedWidthStill
    case FixedWidthDownsampled
    case FixedHeightSmall
    case FixedHeightSmallStill
    case FixedWidthSmall
    case FixedWidthSmallStill
    case Downsized
    case DownsizedStill
    case DownsizedLarge
    case Original
    case OriginalStill
    case Unknown
}
