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
@testable import WireDataModel

class ZMAssetClientMessageTests_Encryption : BaseZMAssetClientMessageTests {

    func decryptedMessageData(_ data: Data, forClient client: UserClient) -> ZMGenericMessage? {
        let otrMessage = ZMNewOtrMessage.builder()!.merge(from: data).build()! as? ZMNewOtrMessage
        XCTAssertNotNil(otrMessage, "Unable to generate OTR message")
        let clientEntries = otrMessage?.recipients.compactMap { $0 }.compactMap { $0.clients }.joined()
        
        guard let entry = clientEntries?.first else { XCTFail("Unable to get client entry"); return nil }
        
        var message : ZMGenericMessage?
        self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
            do {
                let decryptedData = try sessionsDirectory.decrypt(entry.text, from: client.sessionIdentifier!)
                message = ZMGenericMessage.builder()!.merge(from: decryptedData).build()! as? ZMGenericMessage
            } catch {
                XCTFail("Failed to decrypt generic message: \(error)")
            }
        }
        return message
    }
    
    
    func testThatItReturnsTheEncryptedPayloadDataForThePlaceholderMessage() {
        self.syncMOC.performAndWait {
            
            // given
            let nonce = UUID.create()
            let mimeType = "text/plain"
            let filename = "document.txt"
            let url = self.testURLWithFilename(filename)
            let data = self.createTestFile(url)
            defer { self.removeTestFile(url) }
            let fileMetadata = ZMFileMetadata(fileURL: url)
            
            // when
            let sut = self.syncConversation.appendOTRMessage(with: fileMetadata, nonce: nonce)!
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertTrue(sut.genericAssetMessage!.asset.hasOriginal())
            
            guard let (encryptedData, _) = sut.encryptedMessagePayloadForDataType(.placeholder) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.user1Client1) else { return XCTFail() }
            
            XCTAssertNotNil(genericMessage)
            XCTAssertTrue(genericMessage.hasAsset())
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            
            let original = genericMessage.asset.original!
            XCTAssertEqual(original.name, filename)
            XCTAssertEqual(original.mimeType, mimeType)
            XCTAssertEqual(original.size, UInt64(data.count))
        }
    }
    
    func testThatItReturnsTheEncryptedMetaDataForTheFileDataMessage() {
        self.syncMOC.performAndWait {
            // given
            let nonce = UUID.create()
            let mimeType = "text/plain"
            let filename = "document.txt"
            let url = self.testURLWithFilename(filename)
            let data = self.createTestFile(url)
            defer { self.removeTestFile(url) }
            let fileMetadata = ZMFileMetadata(fileURL: url)
            let sut = self.syncConversation.appendOTRMessage(with: fileMetadata, nonce: nonce)!
            
            // when
            let (otrKey, sha256) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            sut.add(.genericMessage(withUploadedOTRKey: otrKey, sha256: sha256, messageID: sut.nonce!))
            
            // then
            guard let (encryptedData, _) = sut.encryptedMessagePayloadForDataType(.fullAsset) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.user1Client1) else { return XCTFail() }
            
            XCTAssertNotNil(genericMessage)
            XCTAssertTrue(genericMessage.hasAsset())
            
            XCTAssertTrue(genericMessage.asset.hasUploaded())
            let uploaded = genericMessage.asset.uploaded!
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
            
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            let original = genericMessage.asset.original!
            XCTAssertEqual(original.name, filename)
            XCTAssertEqual(original.mimeType, mimeType)
            XCTAssertEqual(original.size, UInt64(data.count))
            
            XCTAssertFalse(original.hasVideo())
        }
    }
    
    func testThatItReturnsTheEncryptedMetaDataForAVideoDataMessage() {
        self.syncMOC.performAndWait {
            
            // given
            let nonce = UUID.create()
            let mimeType = "video/mp4"
            let duration : TimeInterval = 15000
            let dimensions = CGSize(width: 1024, height: 768)
            let name = "cats.mp4"
            let url = self.testURLWithFilename(name)
            let data = self.createTestFile(url)
            let size = data.count
            defer { self.removeTestFile(url) }
            let videoMetadata = ZMVideoMetadata(fileURL: url, duration: duration, dimensions: dimensions)
            let sut = syncConversation.appendOTRMessage(with: videoMetadata, nonce: nonce)!
            
            // when
            let (otrKey, sha256) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            sut.add(.genericMessage(withUploadedOTRKey: otrKey, sha256: sha256, messageID: sut.nonce!))
            
            // then
            guard let (encryptedData, _) = sut.encryptedMessagePayloadForDataType(.fullAsset) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.syncUser1Client1) else { return XCTFail() }
            
            XCTAssertNotNil(genericMessage)
            XCTAssertTrue(genericMessage.hasAsset())
            
            XCTAssertTrue(genericMessage.asset.hasUploaded())
            let uploaded = genericMessage.asset.uploaded!
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
            
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            let original = genericMessage.asset.original!
            XCTAssertEqual(original.name, name)
            XCTAssertEqual(original.mimeType, mimeType)
            XCTAssertEqual(original.size, UInt64(size))
            
            XCTAssertTrue(original.hasVideo())
            let video = original.video!
            XCTAssertEqual(video.durationInMillis, UInt64(duration * 1000))
            XCTAssertEqual(video.width, Int32(dimensions.width))
            XCTAssertEqual(video.height, Int32(dimensions.height))
        }
    }
    
    func testThatItItReturnsTheEncryptedGenericMessageDataIncludingThe_NotUploaded_WhenItIsPresent() {
        self.syncMOC.performAndWait {
            // given
            let fileMetadata = self.addFile()
            let sut = syncConversation.appendOTRMessage(with: fileMetadata, nonce: UUID.create())!
            sut.delivered = true
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when we cancel the transfer
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            
            // then the genereted encrypted message should include the Asset.original and Asset.NotUploaded
            guard let (encryptedData, _) = sut.encryptedMessagePayloadForDataType(.placeholder) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.syncUser1Client1) else { return XCTFail() }
            
            XCTAssertTrue(genericMessage.asset.hasNotUploaded())
            XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
            XCTAssertTrue(genericMessage.asset.hasOriginal())
        }
    }
}


// MARK: - MissingClientStrategy
extension ZMAssetClientMessageTests_Encryption {

    
    func setupConversation(conversation: ZMConversation){
        conversation.connection = ZMConnection.insertNewObject(in: syncMOC)
        conversation.connection?.to = ZMUser.insertNewObject(in: syncMOC)
        conversation.connection?.to.remoteIdentifier = UUID()
        conversation.conversationType = .oneOnOne
    }
    
    func insertFileMessage() -> ZMAssetClientMessage{
        let sut = syncConversation.appendOTRMessage(with: addFile(), nonce: UUID.create())!
        let (otrKey, sha256) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        sut.add(.genericMessage(withUploadedOTRKey: otrKey, sha256: sha256, messageID: sut.nonce!, expiresAfter: NSNumber(value: sut.deletionTimeout)))
        return sut
    }
    
    
    func testThatItReturnsCorrectStrategyForEphemeralMessages_FileAssets(){
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.setupConversation(conversation: self.syncConversation)
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let sut = self.insertFileMessage()
            XCTAssertTrue(sut.isEphemeral)

            // when
            guard let (_, strategy) = sut.encryptedMessagePayloadForDataType(.fullAsset) else { return XCTFail() }

            //then
            XCTAssertEqual(strategy, MissingClientsStrategy.doNotIgnoreAnyMissingClient)
        }
    }
    
    func testThatItReturnsCorrectStrategyForEphemeralMessages_FileAssets_GroupConversation(){
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let sut = self.insertFileMessage()
            XCTAssertTrue(sut.isEphemeral)
            
            // when
            guard let (_, strategy) = sut.encryptedMessagePayloadForDataType(.fullAsset) else { return XCTFail() }
            
            //then
            XCTAssertEqual(strategy, MissingClientsStrategy.doNotIgnoreAnyMissingClient)
        }
    }
    
    func testThatItReturnsCorrectStrategyForNormalMessages_FileAssets(){
        self.syncMOC.performAndWait {
            // given
            self.setupConversation(conversation: self.syncConversation)
            let sut = self.insertFileMessage()
            XCTAssertFalse(sut.isEphemeral)

            // when
            guard let (_, strategy) = sut.encryptedMessagePayloadForDataType(.fullAsset) else { return XCTFail() }

            // then
            XCTAssertEqual(strategy, MissingClientsStrategy.doNotIgnoreAnyMissingClient)
        }
    }
}



