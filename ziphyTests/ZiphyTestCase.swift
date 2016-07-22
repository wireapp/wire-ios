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


import UIKit
import XCTest
import ziphy

class GiphyRequester : ZiphyURLRequester {
    
    let apiKey:String
    let searchSession:NSURLSession
    
    init(apiKey:String) {
        
        self.apiKey = apiKey
        self.searchSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    @objc func doRequest(request: NSURLRequest, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        
        if let originalURL:NSURL = request.URL {
            
            var urlString = originalURL.absoluteString
            urlString = urlString+"&api_key=\(self.apiKey)"
            
            let newURL = NSURL(string: urlString)
            
            let task = self.searchSession.dataTaskWithURL(newURL!, completionHandler: completionHandler)
            task.resume()
        }
        else {
            completionHandler(nil, nil,NSError(domain: "requester.error",
                code: 1,
                userInfo:[NSLocalizedDescriptionKey:"Request"]))
        }
        
    }
}

class ZiphyTestCase: XCTestCase {
    //Public API key dc6zaTOxFJmzC
    let defaultRequester:GiphyRequester = GiphyRequester(apiKey: "dc6zaTOxFJmzC")
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
