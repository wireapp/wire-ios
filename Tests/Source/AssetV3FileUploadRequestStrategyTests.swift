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


class AssetV3FileUploadRequestStrategyTests: MessagingTest {

    fileprivate var registrationStatus: MockClientRegistrationStatus!
    fileprivate var cancellationProvider: MockTaskCancellationProvider!
    fileprivate var sut : AssetV3FileUploadRequestStrategy!
    fileprivate var conversation: ZMConversation!
    fileprivate var data: Data!
    private var testFileURL: URL!

    override func setUp() {
        super.setUp()
        registrationStatus = MockClientRegistrationStatus()
        cancellationProvider = MockTaskCancellationProvider()
        sut = AssetV3FileUploadRequestStrategy(clientRegistrationStatus: registrationStatus, taskCancellationProvider: cancellationProvider, managedObjectContext: syncMOC)
        conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        testFileURL = testURLWithFilename("file.dat")
        createSelfClient()
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
        let message = conversation.appendMessage(with: metadata, version3: true) as! ZMAssetClientMessage
        syncMOC.saveOrRollback()

        XCTAssert(message.genericAssetMessage?.assetData?.hasUploaded() == false)
        return message
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        message.transferState = .uploading
        message.uploadState = .uploadingFullAsset

        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(message.nonce, fileName: message.fileMessageData!.filename, encrypted: true))
    }

// MARK: – Request Generation

    func testThatItDoesNotGenerateARequestIfTheUploadedStateIsWrong() {
        // given
        let message = createFileMessage()
        prepareUpload(of: message)

        // when
        message.uploadState = .done
        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotGenerateARequestIfTheTransferStateIsWrong() {
        // given
        let message = createFileMessage()
        prepareUpload(of: message)

        // when
        message.transferState = .downloaded
        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotGenerateARequestIfTheStatesAreCorrectButTheFileIsNotPreprocessed() {
        // given
        let message = createFileMessage()

        // when
        message.transferState = .uploading
        message.uploadState = .uploadingFullAsset

        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesGenerateARequestIfTheStatesAreCorrectAndTheFileIsPreprocessed() {
        // given
        let message = createFileMessage()

        // when
        prepareUpload(of: message)
        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }
        XCTAssertEqual(request.path, "/assets/v3")
        XCTAssertEqual(request.method, .methodPOST)
    }

    func testThatItGeneratesARequestForAnEphemeralV3FileMessage() {
        // given
        let message = createFileMessage(ephemeral: true)

        // when
        prepareUpload(of: message)
        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }
        XCTAssertEqual(request.path, "/assets/v3")
        XCTAssertEqual(request.method, .methodPOST)
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
        // given
        let message = createFileMessage(ephemeral: ephemeral)
        let (assetKey, token) = (UUID.create().transportString(), UUID.create().transportString())

        prepareUpload(of: message)
        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        guard let request = sut.nextRequest() else { return XCTFail("No request generated", line: line) }
        XCTAssertEqual(request.path, "/assets/v3", line: line)
        XCTAssertEqual(request.method, .methodPOST, line: line)

        var payload = ["key": assetKey]
        if includeToken {
            payload["token"] = token
        }
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil)
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
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

    func testThatItSetsTheStateToUploadingFailedAndAddsAssetNotUploadedWhenTheRequestFails() {
        // given
        let message = createFileMessage()
        prepareUpload(of: message)
        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }
        XCTAssertEqual(request.path, "/assets/v3")
        XCTAssertEqual(request.method, .methodPOST)

        let response = ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let asset = message.genericAssetMessage?.assetData else { return XCTFail("No asset data") }
        XCTAssertTrue(asset.hasNotUploaded())
        XCTAssertFalse(asset.uploaded.hasAssetId())
        XCTAssertEqual(message.uploadState, .uploadingFailed)
    }

}
