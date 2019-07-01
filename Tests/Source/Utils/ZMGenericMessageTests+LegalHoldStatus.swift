//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class ZMGenericMessageTests_LegalHoldStatus: XCTestCase {
    
    var allContentTypes: [PBGeneratedMessage] {
        let knock = ZMKnock.knock()
        let text = ZMText.text(with: "Hello 👩‍💻👨‍👩‍👧!")
        let ephermalText = ZMEphemeral.ephemeral(content: text, expiresAfter: 0)
        let location = ZMLocation.location(withLatitude: 0, longitude: 0)
        let external = ZMExternal.external(withOTRKey: Data(), sha256: Data())
        let asset = ZMAsset.asset(withNotUploaded: .CANCELLED)
        let imageProperties = ZMIImageProperties(size: .zero, length: 0, mimeType: "image/jpeg")
        let imageAsset = ZMImageAsset(mediumProperties: imageProperties, processedProperties: imageProperties, encryptionKeys: nil, format: .medium)
        let availability = ZMAvailability.availability(.busy)
        let messageDelete = ZMMessageDelete.delete(messageId: UUID())
        let messageHide = ZMMessageHide.hide(conversationId: UUID(), messageId: UUID())
        let messageEdit = ZMMessageEdit.edit(with: text, replacingMessageId: UUID())
        let reaction = ZMReaction.reaction(emojiString: "❤️", messageId: UUID())
        let confirmation = ZMConfirmation.confirm(messageId: UUID())
        let lastRead = ZMLastRead(timestamp: Date(), conversationRemoteID: UUID())!
        let cleared = ZMCleared(timestamp: Date(), conversationRemoteID: UUID())!
        let calling = ZMCalling.calling(message: "calling")
        
        return [knock,
                text,
                ephermalText,
                location,
                external,
                asset,
                imageAsset,
                availability,
                messageDelete,
                messageHide,
                messageEdit,
                reaction,
                confirmation,
                lastRead,
                cleared,
                calling]
    }
    
    func testThatLegalHoldStatusCanBeUpdatedForSupportedContentTypes() {
        // GIVEN
        let contentTypesSupportingLegalHoldStatus = [ZMKnock.self, ZMText.self, ZMEphemeral.self, ZMAsset.self, ZMLocation.self, ZMReaction.self]
        let contentSupportingLegalHoldStatus = allContentTypes.filter({ content in contentTypesSupportingLegalHoldStatus.any({ content.isKind(of: $0) }) })
        let contentNotSupportingLegalHoldStatus = allContentTypes.filter({ content in !contentTypesSupportingLegalHoldStatus.any({ content.isKind(of: $0) }) })
        
        for content in contentSupportingLegalHoldStatus {
            // WHEN
            let updatedContent = (content as! MessageContentType).updateLegalHoldStatus(.ENABLED)!
            
            // THEN
            XCTAssertTrue(updatedContent.hasLegalHoldStatus())
            XCTAssertEqual(updatedContent.legalHoldStatus, .ENABLED)
        }
        
        for content in contentNotSupportingLegalHoldStatus {
            // WHEN
            let updatedContent = (content as! MessageContentType).updateLegalHoldStatus(.ENABLED)
            
            // THEN
            XCTAssertNil(updatedContent)
        }
    }

}
