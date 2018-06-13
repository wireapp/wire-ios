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



func performOnQueue(_ callBackQueue:DispatchQueue, a:@escaping ()->() ){
    
    callBackQueue.async(execute: a)
}

enum Either<L, R> {
    
    case left(L)
    case right(R)
    
    var isLeft: Bool {
        switch self {
        case .left: return true
        case .right: return false
        }
    }
    
    var isRight: Bool {
        switch self {
        case .right: return true
        case .left: return false
        }
    }
    
    var right: R? {
        switch self {
        case let .right(r): return r
        case .left: return nil
        }
    }
    
    var left: L? {
        switch self {
        case let .left(l): return l
        case .right: return nil
        }
    }
    
    func bimap<B, D>(_ f : (L) -> B, _ g : ((R) -> D)) -> Either<B, D> {
        switch self {
        case let .left(bx): return .left(f(bx))
        case let .right(bx): return .right(g(bx))
        }
    }
    
    @discardableResult func leftMap<B>(_ f : (L) -> B) -> Either<B, R> {
        return bimap(f, identity)
    }
    
    @discardableResult func rightMap<D>(_ g : (R) -> D) -> Either<L, D> {
        return bimap(identity, g)
    }
    
    func identity<A>(_ a: A) -> A {
        return a
    }

}

typealias URLRequestCallBack = (_ data:Data?, _ response:URLResponse?, _ error:Error?)->Error?

public protocol CancelableTask {
    func cancel()
}

class URLRequestPromise : CancelableTask {
    
    let requester: ZiphyURLRequester
    var pending: [URLRequestCallBack] = []
    var onFailure: (_ error: Error) -> () = { error in return }
    var failure: Error? = nil
    var requestIdentifier: ZiphyRequestIdentifier?
    
    init(requester: ZiphyURLRequester) {
        self.requester = requester
    }
    
    @discardableResult func resolve() -> URLRequestCallBack {
        
        func performAResolution(_ data:Data?, response:URLResponse?, error:Error?) -> Error? {
            
            if error != nil {
                
                onFailure(error!)
                return nil
            }
            
            for f in self.pending {
                
                self.failure = f(data, response, error)
                
                if let error = self.failure {
                    
                    onFailure(error)
                    break
                }
            }
            
            return nil
        }
        
        return performAResolution
    }
    
    @discardableResult func fail(_ onFailure: @escaping (_ error: Error) ->() ) -> URLRequestPromise {
        
        self.onFailure = onFailure
        return self
    }
    
    func reject(_ error:Error) {
        
        self.failure = error
    }
    
    func then(_ what: @escaping URLRequestCallBack) -> URLRequestPromise {
        
        self.pending.append(what)
        return self
    }
    
    func cancel() {
        if let requestIdentifier = requestIdentifier {
            self.requester.cancelRequest(withRequestIdentifier: requestIdentifier)
        }
    }
}

@objc public protocol ZiphyRequestIdentifier { }

@objc public protocol ZiphyURLRequester {
    
    func doRequest(_ request: URLRequest, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> ZiphyRequestIdentifier
    func cancelRequest(withRequestIdentifier requestIdentifier: ZiphyRequestIdentifier)
}

extension URLSessionDataTask : ZiphyRequestIdentifier { }

extension URLSession : ZiphyURLRequester {
    public func doRequest(_ request: URLRequest, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> ZiphyRequestIdentifier {
        let task = self.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }
    
    public func cancelRequest(withRequestIdentifier requestIdentifier: ZiphyRequestIdentifier) {
        if let task = requestIdentifier as? URLSessionDataTask {
            task.cancel()
        }
    }
}

@objc public enum ZiphyImageType:Int {
    case fixedHeight
    case fixedHeightStill
    case fixedHeightDownsampled
    case fixedWidth
    case fixedWidthStill
    case fixedWidthDownsampled
    case fixedHeightSmall
    case fixedHeightSmallStill
    case fixedWidthSmall
    case fixedWidthSmallStill
    case downsized
    case downsizedStill
    case downsizedLarge
    case original
    case originalStill
    case unknown
}
