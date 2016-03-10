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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import XCTest

class ObjectObserverTokenRegistryTests: XCTestCase {
    
    class TestToken : NSObject, RegisteredObjectObserverToken {
        let object: NSObject
        init(object: NSObject) {
            self.object = object
            super.init()
        }
    }
    
    func testThatItAppliesToRegisteredTokens() {
        // given
        let sut = zmessaging.ObjectObserverTokenRegistry()
        let a = NSObject()
        let b = NSObject()
        let tokenA1 = TestToken(object: a)
        let tokenA2 = TestToken(object: a)
        let tokenB = TestToken(object: b)
        
        // when
        sut.registerToken(tokenA1)
        sut.registerToken(tokenA2)
        sut.registerToken(tokenB)
        
        var appliedTokens: [TestToken] = []
        sut.applyTokensForObject(a) { (token: TestToken) -> Void in
            appliedTokens.append(token)
        }
        XCTAssert(appliedTokens == [tokenA1, tokenA2] || appliedTokens == [tokenA2, tokenA1])
    }

    func testThatItDoesNotApplyToUnregisteredTokens() {
        // given
        let sut = zmessaging.ObjectObserverTokenRegistry()
        let a = NSObject()
        let tokenA1 = TestToken(object: a)
        let tokenA2 = TestToken(object: a)
        
        // when
        sut.registerToken(tokenA1)
        sut.registerToken(tokenA2)
        sut.unregisterToken(tokenA1)
        
        var appliedTokens: [TestToken] = []
        sut.applyTokensForObject(a) { (token: TestToken) -> Void in
            appliedTokens.append(token)
        }
        XCTAssertEqual(appliedTokens, [tokenA2])
    }
}
