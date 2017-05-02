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
@testable import WireMessageStrategy
import WireRequestStrategy
import XCTest
import WireDataModel

class AssetV3FileUploadRequestStrategyTests: MessagingTestBase {

    fileprivate var mockApplicationStatus : MockApplicationStatus!
    fileprivate var sut : AssetV3FileUploadRequestStrategy!
    fileprivate var conversation: ZMConversation!
    fileprivate var data: Data!
    private var testFileURL: URL!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing

        self.syncMOC.performGroupedBlockAndWait {
            self.sut = AssetV3FileUploadRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: self.mockApplicationStatus)
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.remoteIdentifier = UUID.create()
        }
        self.testFileURL = self.testURLWithFilename("file.dat")
    }

    // MARK: - Helpers

    func addFile() -> ZMFileMetadata {
        data = createTestFile(testFileURL)
        return ZMFileMetadata(fileURL: testFileURL)
    }

    func testURLWithFilename(_ filename: String) -> URL {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: documents).appendingPathComponent(filename)
    }

    @discardableResult func createTestFile(_ url: URL) -> Data {
        let data: Data! = "Some other data".data(using: String.Encoding.utf8)
        try! data.write(to: url, options: [])
        return data
    }

    func removeTestFile(_ url: URL) {
        do {
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            try FileManager.default.removeItem(at: url)
        } catch {
            XCTFail("Error removing file: \(error)")
        }
    }

    func createFileMessage(ephemeral: Bool = false) -> ZMAssetClientMessage {
        conversation.messageDestructionTimeout = ephemeral ? 10 : 0
        let metadata = addFile()
        let message = conversation.appendMessage(with: metadata) as! ZMAssetClientMessage
        syncMOC.saveOrRollback()

        XCTAssert(message.genericAssetMessage?.assetData?.hasUploaded() == false)
        return message
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        message.transferState = .uploading
        message.uploadState = .uploadingFullAsset

        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(message.nonce, fileName: message.fileMessageData!.filename, encrypted: true))
    }

// MARK: Preprocessing


    // In very rare cases it happened that file messages (sent using the /assets/v3 endpoint) could not be decrypted on the receiving side,
    // this only happened for file messages and not images (which are also files and sent using the same endpoint, but by a different RequestStrategy). 
    // The odd thing to note here is was 100% reproducibly which specific files on specific devices, the sha256 did not match the file data. 
    // The underlying bug was, that the FilePreprocessor, which encrypts the file, updates the generic message with the otrKey and sha256 had 
    // a wrong predicate. The predicate did not check if there already were encryption keys in the generic message and would thus preprocess the file again.
    // This means that in specific cases the file gets preprocessed and the encrypted binary data gets uploaded to /assets/v3/ while in the meantime the
    // file preprocessor might encrypt the file again and update the generic message data with the new keys, which won't match the uploaded data. 
    // The message sent to the receiving clients thus could contain encryption keys which would not match the data they would download from /assets/v3.
    func testThatItDoesPreprocessTheFileOnlyOnce() {
        var message: ZMAssetClientMessage!
        var otrKey: Data!
        var sha256: Data!

        syncMOC.performGroupedBlock {
            // GIVEN
            message = self.createFileMessage()
            message.transferState = .uploading
            message.uploadState = .uploadingFullAsset

            do {
                guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No asset data") }
                XCTAssertFalse(assetData.uploaded.hasOtrKey())
                XCTAssertFalse(assetData.uploaded.hasSha256())
            }

            // WHEN
            ZMChangeTrackerBootstrap.bootStrapChangeTrackers(self.sut.contextChangeTrackers, on: self.syncMOC)

            do {
                // THEN
                guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No asset data") }
                XCTAssertTrue(assetData.uploaded.hasOtrKey())
                XCTAssertTrue(assetData.uploaded.hasSha256())
                otrKey = assetData.uploaded.otrKey
                sha256 = assetData.uploaded.sha256
            }

            // WHEN
            // As soon as the upload to `/assets/v3` succeds, we delete the encrypted data.
            // This previously triggered the preprocessor again.
            message.managedObjectContext?.zm_fileAssetCache.deleteAssetData(
                message.nonce,
                fileName: message.genericAssetMessage!.v3_fileCacheKey,
                encrypted: true
            )

            // WHEN
            ZMChangeTrackerBootstrap.bootStrapChangeTrackers(self.sut.contextChangeTrackers, on: self.syncMOC)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlock {
            guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No asset data") }
            XCTAssertEqual(assetData.uploaded.otrKey, otrKey)
            XCTAssertEqual(assetData.uploaded.sha256, sha256)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

// MARK: – Request Generation

    func testThatItDoesNotGenerateARequestIfTheUploadedStateIsWrong() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileMessage()
            self.prepareUpload(of: message)
            
            // WHEN
            message.uploadState = .done
            self.syncMOC.saveOrRollback()
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItDoesNotGenerateARequestIfTheTransferStateIsWrong() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileMessage()
            self.prepareUpload(of: message)
            
            // WHEN
            message.transferState = .downloaded
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItDoesNotGenerateARequestIfTheStatesAreCorrectButTheFileIsNotPreprocessed() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileMessage()
            
            // WHEN
            message.transferState = .uploading
            message.uploadState = .uploadingFullAsset
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItDoesGenerateARequestIfTheStatesAreCorrectAndTheFileIsPreprocessed() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileMessage()
            
            // WHEN
            self.prepareUpload(of: message)
            
            // THEN
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            XCTAssertEqual(request.path, "/assets/v3")
            XCTAssertEqual(request.method, .methodPOST)
        }
    }

    func testThatItGeneratesARequestForAnEphemeralV3FileMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileMessage(ephemeral: true)
            
            // WHEN
            self.prepareUpload(of: message)
            
            // THEN
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            XCTAssertEqual(request.path, "/assets/v3")
            XCTAssertEqual(request.method, .methodPOST)
        }
    }

    // MARK: Response Parsing

    func testThatItUpdatesTheMessageWithTheAssetId() {
        assertThatItUpdatesTheAssetIdFromTheResponse()
    }

    func testThatItUpdatesTheMessageWithTheAssetIdAndToken() {
        assertThatItUpdatesTheAssetIdFromTheResponse(includeToken: true)
    }

    func testThatItUpdatesTheMessageWithTheAssetId_Ephemeral() {
        assertThatItUpdatesTheAssetIdFromTheResponse(ephemeral: true)
    }

    func testThatItUpdatesTheMessageWithTheAssetIdAndToken_Ephemeral() {
        assertThatItUpdatesTheAssetIdFromTheResponse(includeToken: true, ephemeral: true)
    }

    func assertThatItUpdatesTheAssetIdFromTheResponse(includeToken: Bool = false, ephemeral: Bool = false, line: UInt = #line) {
        // GIVEN
        var message: ZMAssetClientMessage!
        let (assetKey, token) = (UUID.create().transportString(), UUID.create().transportString())
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileMessage(ephemeral: ephemeral)
            self.prepareUpload(of: message)
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated", line: line) }
            XCTAssertEqual(request.path, "/assets/v3", line: line)
            XCTAssertEqual(request.method, .methodPOST, line: line)
            
            var payload = ["key": assetKey]
            if includeToken {
                payload["token"] = token
            }
            let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil)
            request.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let uploaded = message.genericAssetMessage?.assetData?.uploaded else { return XCTFail("No uploaded message", line: line) }
            XCTAssertTrue(uploaded.hasOtrKey(), line: line)
            XCTAssertTrue(uploaded.hasSha256(), line: line)
            XCTAssertTrue(uploaded.hasAssetId(), line: line)
            XCTAssertEqual(uploaded.hasAssetToken(), includeToken, line: line)
            XCTAssertEqual(uploaded.assetId, assetKey, line: line)
            if includeToken {
                XCTAssertEqual(uploaded.assetToken, token, line: line)
            }
        }
    }

    func testThatItSetsTheStateToUploadingFailedAndAddsAssetNotUploadedWhenTheRequestFails() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            message = self.createFileMessage()
            self.prepareUpload(of: message)
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            XCTAssertEqual(request.path, "/assets/v3")
            XCTAssertEqual(request.method, .methodPOST)
            
            let response = ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
            request.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let asset = message.genericAssetMessage?.assetData else { return XCTFail("No asset data") }
            XCTAssertTrue(asset.hasNotUploaded())
            XCTAssertFalse(asset.uploaded.hasAssetId())
            XCTAssertEqual(message.uploadState, .uploadingFailed)
        }
    }

}
