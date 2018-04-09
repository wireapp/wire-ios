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
    let trendingEndpoint:String
    let gifsEndpoint:String
    
    fileprivate func requestWithParameters(_ endPoint:String, query:String? = nil) -> Either<Error, URLRequest> {
        
        var components = URLComponents()
        
        components.scheme = self.requestScheme
        components.host = self.host
        
        let path = self.apiVersionPath + endPoint
        
        components.path = path
        components.query = query ?? ""
        
        if let requestURL = components.url {
            
            return Either.Right(URLRequest(url: requestURL))
        }
        else {
            
            let invalidURL = requestScheme + "://" + ((self.host as NSString).appendingPathComponent(path) as NSString).appendingPathComponent(query ?? "")
            
            return Either.Left(NSError(domain: ZiphyErrorDomain,
                code: ZiphyError.malformedURL.rawValue,
                userInfo:[NSLocalizedDescriptionKey:invalidURL + " is not a valid URL"]))
        }
    }
    
    func trendingRequestWithParameters(resultsLimit:Int, offset:Int) -> Either<Error, URLRequest> {
        return self.requestWithParameters(self.trendingEndpoint, query: "limit=\(resultsLimit)&offset=\(offset)")
    }
    
    func searchRequestWithParameters(_ term:String, resultsLimit:Int, offset:Int) -> Either<Error, URLRequest> {
        
        let query = "limit=\(resultsLimit)&offset=\(offset)"
        
        return self.requestWithParameters(self.searchEndpoint, query: query).rightMap { (urlRequest: URLRequest) in
            
            let escapedSearchTerm = self.escape(term)
            let finalSearchTerm = escapedSearchTerm
            LogDebug("Escaped search term from \(term) to \(finalSearchTerm)")
            let finalURLString = urlRequest.url!.absoluteString+"&q=\(finalSearchTerm)"
            LogDebug("Create request with URL: \(finalURLString)")
            
            return URLRequest(url: URL(string: finalURLString)!)
        }
    }
    
    func randomRequests() -> Either<Error, URLRequest> {
        
        return self.requestWithParameters(self.randomEndpoint)
    }
    
    func gifsByIdRequest(_ ids:[String]) -> Either<Error, URLRequest> {
        
        let commaSeparatedIds = ids.reduce("", { $0 == "" ? $1 : $0 + "," + $1 })
        let query = String(format:"ids=%@", commaSeparatedIds)
        
        return self.requestWithParameters(self.gifsEndpoint, query: query)
        
    }
    
    fileprivate func escape(_ string: String) -> String {
        
        let funkyChars = "!*'\"();:@&=+$,/?%#[]% "
        
        let legalURLCharactersToBeEscaped: CFString = funkyChars as CFString
        return CFURLCreateStringByAddingPercentEscapes(nil, string as CFString, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    
}
