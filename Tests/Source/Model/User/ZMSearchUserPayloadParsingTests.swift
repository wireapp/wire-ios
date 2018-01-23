//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import XCTest

class ZMSearchUserPayloadParsingTests: ZMBaseManagedObjectTest {
    func testThatItParsesTheBasicPayload() {
        // given
        let uuid = UUID()
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString()]
        
        // when
        let user = ZMSearchUser(payload: payload, userSession: self)!
        
        // then
        XCTAssertEqual(user.name, "A user that was found")
        XCTAssertEqual(user.handle, "@user")
        XCTAssertEqual(user.remoteIdentifier, uuid)
        XCTAssertEqual(user.accentColorValue, ZMAccentColor.init(rawValue: 5))
        XCTAssertNil(user.serviceUser)
        XCTAssertFalse(user.isServiceUser)
    }
    
    func testThatItParsesService_ProviderIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString()]
        
        // when
        let user = ZMSearchUser(payload: payload, userSession: self)!
        
        // then
        XCTAssertNotNil(user.serviceUser)
        XCTAssert(user.isServiceUser)
        XCTAssertEqual(user.serviceUser!.providerIdentifier, provider.transportString())
        XCTAssertEqual(user.serviceUser!.serviceIdentifier, uuid.transportString())
    }
    
    func testThatItParsesService_ImageIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "preview",
                                                  "key": assetKey]]]
        
        // when
        let _ = ZMSearchUser(payload: payload, userSession: self)!
        
        // then
        let userAsset = ZMSearchUser.searchUserToMediumAssetIDCache().object(forKey: uuid as NSUUID) as! SearchUserAssetObjC
        
        XCTAssertNotNil(userAsset)
        XCTAssertEqual(userAsset.assetKey, assetKey)
    }
    
    func testThatItParsesService_IgnoresOtherImageIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "full",
                                                  "key": assetKey]]]
        
        // when
        let _ = ZMSearchUser(payload: payload, userSession: self)!
        
        // then
        XCTAssertNil(ZMSearchUser.searchUserToMediumAssetIDCache().object(forKey: uuid as NSUUID))
    }
}


extension ZMSearchUserPayloadParsingTests: ZMManagedObjectContextProvider {
    var managedObjectContext: NSManagedObjectContext! {
        return self.uiMOC
    }
    
    var syncManagedObjectContext: NSManagedObjectContext! {
        return self.syncMOC
    }
}
