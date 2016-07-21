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


struct ZiphyRequestGenerator {
    
    let host:String
    let requestScheme:String
    let apiVersionPath:String
    let searchEndpoint:String
    let randomEndpoint:String
    let gifsEndpoint:String
    
    private func requestWithParameters(endPoint:String, query:String? = nil) -> Either<NSError, NSURLRequest> {
        
        let components = NSURLComponents()
        
        components.scheme = self.requestScheme
        components.host = self.host
        
        let path = self.apiVersionPath.stringByAppendingString(endPoint)
        
        components.path = path
        components.query = query ?? ""
        
        if let requestURL = components.URL {
            
            return Either.Right(Box(value: NSURLRequest(URL: requestURL)))
        }
        else {
            
            let invalidURL = requestScheme + "://" + ((self.host as NSString).stringByAppendingPathComponent(path) as NSString).stringByAppendingPathComponent(query ?? "")
            
            return Either.Left(Box(value: NSError(domain: ZiphyErrorDomain,
                code: ZiphyError.MalformedURL.rawValue,
                userInfo:[NSLocalizedDescriptionKey:invalidURL + " is not a valid URL"])))
        }
    }
    
    func searchRequestWithParameters(term:String, resultsLimit:Int, offset:Int) -> Either<NSError, NSURLRequest> {
        
        let query = "limit=\(resultsLimit)&offset=\(offset)"
        
        switch self.requestWithParameters(self.searchEndpoint, query: query) {
            
        case .Left(let box):
            return Either.Left(box)
        case .Right(let box):
            let url:NSURL! = box.value.URL
            let escapedSearchTerm = self.escape(term)
            let finalSearchTerm = escapedSearchTerm ?? ""
            LogDebug("Escaped search term from \(term) to \(finalSearchTerm)")
            let finalURLString = url.absoluteString+"&q=\(finalSearchTerm)"
            LogDebug("Create request with URL: \(finalURLString)")
            return Either.Right(Box(value: NSURLRequest(URL: NSURL(string: finalURLString)!)))
        }
    }
    
    func randomRequests() -> Either<NSError, NSURLRequest> {
        
        return self.requestWithParameters(self.randomEndpoint)
    }
    
    func gifsByIdRequest(ids:[String]) -> Either<NSError, NSURLRequest> {
        
        let commaSeparatedIds = ids.reduce("", combine:{ $0 == "" ? $1 : $0 + "," + $1 })
        let query = String(format:"ids=%@", commaSeparatedIds)
        
        return self.requestWithParameters(self.gifsEndpoint, query: query)
        
    }
    
    private func escape(string: String) -> String {
        
        let funkyChars = "!*'\"();:@&=+$,/?%#[]% "
        
        let legalURLCharactersToBeEscaped: CFStringRef = funkyChars
        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    
}