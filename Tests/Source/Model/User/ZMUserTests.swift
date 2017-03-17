//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
@testable import ZMCDataModel

extension ZMUserTests {
    func testThatSettingUserProfileAssetIdentifiersDirectlyDoesNotMarkAsModified() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)
        
        // WHEN
        user.previewProfileAssetIdentifier = "foo"
        user.completeProfileAssetIdentifier = "bar"

        // THEN
        XCTAssertFalse(user.hasLocalModifications(forKey: #keyPath(ZMUser.previewProfileAssetIdentifier)))
        XCTAssertFalse(user.hasLocalModifications(forKey: #keyPath(ZMUser.completeProfileAssetIdentifier)))
    }

    
    func testThatSettingUserProfileAssetIdentifiersMarksKeysAsModified() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)
        
        // WHEN
        user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: "foo", completeIdentifier: "bar")
        
        // THEN
        XCTAssert(user.hasLocalModifications(forKey: #keyPath(ZMUser.previewProfileAssetIdentifier)))
        XCTAssert(user.hasLocalModifications(forKey: #keyPath(ZMUser.completeProfileAssetIdentifier)))
    }
    
    func testThatSettingUserProfileAssetIdentifiersDoNothingForNonSelfUsers() {
        // GIVEN
        let initialPreview = "123456"
        let initialComplete = "987654"
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.previewProfileAssetIdentifier = initialPreview
        user.completeProfileAssetIdentifier = initialComplete
        
        // WHEN
        user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: "foo", completeIdentifier: "bar")
        
        // THEN
        XCTAssertEqual(user.previewProfileAssetIdentifier, initialPreview)
        XCTAssertEqual(user.completeProfileAssetIdentifier, initialComplete)
    }
    
}
