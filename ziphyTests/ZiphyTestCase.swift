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
    let searchSession:URLSession
    
    init(apiKey:String) {
        
        self.apiKey = apiKey
        self.searchSession = URLSession(configuration: URLSessionConfiguration.default)
    }
    
    func doRequest(_ request: URLRequest, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> ZiphyRequestIdentifier {
        var urlString = request.url!.absoluteString
        urlString = urlString+"&api_key=\(self.apiKey)"
        
        let newURL = URL(string: urlString)
        
        let task = self.searchSession.dataTask(with: newURL!, completionHandler: completionHandler)
        task.resume()
        return task
    }
    
    func cancelRequest(withRequestIdentifier requestIdentifier: ZiphyRequestIdentifier) {
        if let task = requestIdentifier as? URLSessionDataTask {
            task.cancel()
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
