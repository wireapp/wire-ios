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

@testable import WireDataModel

class ZMGenericMessageTests_Hashing: XCTestCase {

    // MARK: - Text

    func testCorrectHashValueForText1() {
        // given
        let textMessage = ZMGenericMessage.message(content: ZMText.text(with: "Hello 👩‍💻👨‍👩‍👧!"))
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = textMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "4f8ee55a8b71a7eb7447301d1bd0c8429971583b15a91594b45dee16f208afd5")
    }
    
    func testCorrectHashValueForText2() {
        // given
        let textMessage = ZMGenericMessage.message(content: ZMText.text(with: "https://www.youtube.com/watch?v=DLzxrzFCyOs"))
        let timestamp = Date(timeIntervalSince1970: 1540213769)
        
        // when
        let hash = textMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "ef39934807203191c404ebb3acba0d33ec9dce669f9acec49710d520c365b657")
    }
    
    func testCorrectHashValueForText3() {
        // given
        let textMessage = ZMGenericMessage.message(content: ZMText.text(with: "بغداد"))
        let timestamp = Date(timeIntervalSince1970: 1540213965)
        
        // when
        let hash = textMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "5830012f6f14c031bf21aded5b07af6e2d02d01074f137d106d4645e4dc539ca")
    }
    
    // MARK: - Location
    
    func testCorrectHashValueForLocation1() {
        // given
        let locationMessage = ZMGenericMessage.message(content: ZMLocation.location(withLatitude: 52.5166667, longitude: 13.4))
        let timestamp = Date(timeIntervalSince1970: 1540213769)
        
        // when
        let hash = locationMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "56a5fa30081bc16688574fdfbbe96c2eee004d1fb37dc714eec6efb340192816")
    }
    
    func testCorrectHashValueForLocation2() {
        // given
        let locationMessage = ZMGenericMessage.message(content: ZMLocation.location(withLatitude: 51.509143, longitude: -0.117277))
        let timestamp = Date(timeIntervalSince1970: 1540213769)
        
        // when
        let hash = locationMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "803b2698104f58772dbd715ec6ee5853d835df98a4736742b2a676b2217c9499")
    }
    
    // MARK: - Asset
    
    func testCorrectHashValueForAsset1() {
        // given
        var assetMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: Data(), sha256: Data()))
        assetMessage = assetMessage.updatedUploaded(withAssetId: "assetId1", token: nil)!
        let timestamp = Date(timeIntervalSince1970: 1540213769)
        
        // when
        let hash = assetMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "eba94f40053c5c854e95d2360a457ec47a7c783d98298476188fa74e729941a9")
    }
    
    // MARK: - Ephemeral
    
    func testCorrectHashValueForEphemeral() {
        // given
        let ephemeralTextMessage = ZMGenericMessage.message(content: ZMText.text(with: "Hello 👩‍💻👨‍👩‍👧!"), expiresAfter: 100)
        let timestamp = Date(timeIntervalSince1970: 1540213769)
        
        // when
        let hash = ephemeralTextMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "4f8ee55a8b71a7eb7447301d1bd0c8429971583b15a91594b45dee16f208afd5")
    }
    
    // MARK: - Edited
    
    func testCorrectHashValueForEdited() {
        // given
        
        let editedTextMessage = ZMGenericMessage.message(content: ZMMessageEdit.edit(with: ZMText.text(with: "Hello 👩‍💻👨‍👩‍👧!"), replacingMessageId: UUID()))
        let timestamp = Date(timeIntervalSince1970: 1540213769)
        
        // when
        let hash = editedTextMessage.hashOfContent(with: timestamp)
        
        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "4f8ee55a8b71a7eb7447301d1bd0c8429971583b15a91594b45dee16f208afd5")
    }

}
