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


import Foundation
import zmessaging

class ZMAssetClientMessageTests : BaseZMClientMessageTests {
    
    var message: ZMAssetClientMessage!
    
    func appendImageMessage() {
        let imageData = verySmallJPEGData()
        let messageNonce = NSUUID.createUUID()
        message = conversation.appendOTRMessageWithImageData(imageData, nonce: messageNonce)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.length), mimeType:"image/jpeg")
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: NSData.randomEncryptionKey(), macKey: NSData.zmRandomSHA256Key(), mac: NSData.zmRandomSHA256Key())
        
        let mediumMessage = ZMGenericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: .Medium)
        message.addGenericMessage(mediumMessage)
        
        let previewMessage = ZMGenericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: .Preview)
        message.addGenericMessage(previewMessage)
    }
    
    func appendImageMessage(format: ZMImageFormat) -> ZMAssetClientMessage {
        let otherFormat = format == ZMImageFormat.Medium ? ZMImageFormat.Preview : ZMImageFormat.Medium
        let imageData = verySmallJPEGData()
        let messageNonce = NSUUID.createUUID()
        let message = conversation.appendOTRMessageWithImageData(imageData, nonce: messageNonce)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.length), mimeType:"image/jpeg")
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: NSData.randomEncryptionKey(), macKey: NSData.zmRandomSHA256Key(), mac: NSData.zmRandomSHA256Key())
        
        let imageMessage = ZMGenericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: format)
        let emptyImageMessage = ZMGenericMessage(mediumImageProperties: nil, processedImageProperties: nil, encryptionKeys: nil, nonce: messageNonce.transportString(), format: otherFormat)
        message.addGenericMessage(imageMessage)
        message.addGenericMessage(emptyImageMessage)
        
        return message
    }

    func testThatItStoresPlainImageMessageDataForPreview() {
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.updateMessageWithImageData(imageData, forFormat: ZMImageFormat.Preview))
        
        let storedData = AssetDirectory().assetData(message.nonce, format: ZMImageFormat.Preview, encrypted: message.isEncrypted)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItStoresPlainImageMessageDataForMedium() {
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.updateMessageWithImageData(imageData, forFormat: ZMImageFormat.Medium))
        
        let storedData = AssetDirectory().assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: message.isEncrypted)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItDecryptsEncryptedImageMessageData() {
        //given
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        let directory = AssetDirectory()
        directory.storeAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false, data: imageData)
        
        let keys = AssetEncryption.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.Medium)
        let encryptedImageData = directory.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: true)
        directory.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData), length: UInt(imageData.length), mimeType: "image/jpeg")
        message.addGenericMessage(ZMGenericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.Medium))
        
        // when
        XCTAssertNotNil(message.updateMessageWithImageData(encryptedImageData, forFormat: ZMImageFormat.Medium))
        
        let decryptedImageData = directory.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        AssertOptionalNotNil(decryptedImageData) { decryptedImageData in
            XCTAssertEqual(decryptedImageData, imageData)
        }
    }
    
    func testThatItDeletesMessageIfImageMessageDataCanNotBeDecrypted() {
        //given
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        //store original image
        let directory = AssetDirectory()
        directory.storeAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false, data: imageData)
        
        //encrypt image
        let keys = AssetEncryption.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.Medium)
        directory.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: true)
        directory.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData), length: UInt(imageData.length), mimeType: "image/jpeg")
        message.addGenericMessage(ZMGenericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.Medium))
        
        // when
        //pass in some wrong data (i.e. plain data instead of encrypted)
        XCTAssertNil(message.updateMessageWithImageData(imageData, forFormat: ZMImageFormat.Medium))
        
        let decryptedImageData = directory.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        XCTAssertNil(decryptedImageData)
        XCTAssertTrue(message.deleted);
    }
    
    
    func testThatItMarksMediumNeededToBeDownloadedIfNoEncryptedNoDecryptedDataStored() {
        
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        let directory = AssetDirectory()
        directory.storeAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false, data: imageData)
        
        let keys = AssetEncryption.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.Medium)
        let encryptedImageData = directory.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: true)!
        directory.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData), length: UInt(imageData.length), mimeType: "image/jpeg")
        message.addGenericMessage(ZMGenericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.Medium))
        
        // when
        XCTAssertNotNil(message.updateMessageWithImageData(encryptedImageData, forFormat: ZMImageFormat.Medium))
        XCTAssertTrue(message.loadedMediumData)
        
        // pretend that there are no encrypted no decrypted message data stored
        // i.e. cache folder is cleared but message is already processed
        directory.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        
        XCTAssertNil(message.imageMessageData.mediumData)
        XCTAssertFalse(message.loadedMediumData)
    }
    
}

// MARK: - Message generation
extension ZMAssetClientMessageTests {
    
    func testThatItSetsGenericMediumAndPreviewDataWhenCreatingMessage()
    {
        // given
        let nonce = NSUUID.createUUID()
        let image = self.verySmallJPEGData()
        
        // when
        let sut = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC)
        
        // then
        XCTAssertNotNil(sut.mediumGenericMessage)
        XCTAssertNotNil(sut.previewGenericMessage)
        
    }
    
    func testThatItSavesTheOriginalFileWhenCreatingMessage()
    {
        // given
        let nonce = NSUUID.createUUID()
        let image = self.verySmallJPEGData()
        
        // when
        _ = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC)
        
        // then
        let fileData = AssetDirectory().assetData(nonce, format: .Original, encrypted: false)
        AssertOptionalEqual(fileData, expression2: image)
    }

    func testThatItSetsTheOriginalImageSize()
    {
        // given
        let nonce = NSUUID.createUUID()
        let image = self.verySmallJPEGData()
        let expectedSize = ZMImagePreprocessor.sizeOfPrerotatedImageWithData(image)
        
        // when
        let sut = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC)
        
        // then
        XCTAssertEqual(expectedSize, sut.originalImageSize())
    }
}

// MARK: - Payload generation
extension ZMAssetClientMessageTests {
    
    func assertPayloadData(payload: NSData!, forMessage message: ZMAssetClientMessage, format: ZMImageFormat) {
        
        let assetMetadata = ZMOtrAssetMetaBuilder().mergeFromData(payload).build() as? ZMOtrAssetMeta
        AssertOptionalNotNil(assetMetadata) { assetMetadata in
            XCTAssertEqual(assetMetadata.isInline(), message.isInlineForFormat(format))
            XCTAssertEqual(assetMetadata.nativePush(), message.isUsingNativePushForFormat(format))
            
            XCTAssertEqual(assetMetadata.sender.client, self.selfClient1.clientId.client)

            self.assertRecipients(assetMetadata.recipients as! [ZMUserEntry])
        }
    }
    
    func testThatItCreatesPayloadData_Medium() {
        
        //given
        let message = appendImageMessage(.Medium)
        
        //when
        let payload = message.encryptedMessagePayloadForImageFormat(.Medium).data()
        
        //then
        assertPayloadData(payload, forMessage: message, format: .Medium)
    }
    
    func testThatItCreatesPayloadData_Preview() {
        
        //given
        let message = appendImageMessage(ZMImageFormat.Preview)
        
        //when
        let payload = message.encryptedMessagePayloadForImageFormat(.Preview).data()
        
        //then
        assertPayloadData(payload, forMessage: message, format: .Preview)
    }
}

// MARK: - Post event
extension ZMAssetClientMessageTests {
    
    func testThatItSetsConversationLastServerTimestampWhenPostingPreview() {
        let message = appendImageMessage(.Preview)
        let date  = NSDate()
        let payload : [NSObject : AnyObject] = ["deleted" : [String:String](), "missing" : [String:String](), "redundant":[String:String](), "time" : date.transportString()]
        
        message.updateWithPostPayload(payload, updatedKeys: Set(arrayLiteral: ZMAssetClientMessage_NeedsToUploadPreviewKey))
        XCTAssertEqual(message.serverTimestamp, message.conversation.lastServerTimeStamp)
    }
    
    func testThatItDoesNotSetConversationLastServerTimestampWhenPostingMedium() {
        let message = appendImageMessage(.Medium)
        let date  = NSDate()
        let payload : [NSObject : AnyObject] = ["deleted" : [String:String](), "missing" : [String:String](), "redundant":[String:String](), "time" : date.transportString()]
        
        message.updateWithPostPayload(payload, updatedKeys: Set(arrayLiteral: ZMAssetClientMessage_NeedsToUploadMediumKey))
        XCTAssertNotEqual(message.serverTimestamp, message.conversation.lastServerTimeStamp)
    }
    
}


// MARK: - Image owner
extension ZMAssetClientMessageTests {
    
    func sampleImageData() -> NSData {
        return self.verySmallJPEGData()
    }
    
    func sampleProcessedImageData(format: ZMImageFormat) -> NSData {
            return "\(StringFromImageFormat(format)) fake data".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
    }
    
    func sampleImageProperties(format: ZMImageFormat) -> ZMIImageProperties {
        let mult = format == .Medium ? 100 : 1
        return ZMIImageProperties(size: CGSizeMake(CGFloat(300*mult), CGFloat(100*mult)), length: UInt(100*mult), mimeType: "image/jpeg")!
    }

    func createAssetClientMessageWithSampleImageAndEncryptionKeys(storeOriginal: Bool, storeEncrypted: Bool, storeProcessed: Bool, imageData: NSData? = nil) -> ZMAssetClientMessage {
        let directory = AssetDirectory()
        let nonce = NSUUID.createUUID()
        let imageData = imageData ?? sampleImageData()
        var genericMessage : [ZMImageFormat : ZMGenericMessage] = [:]
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            let processedData = sampleProcessedImageData(format)
            let otrKey = NSData.randomEncryptionKey()
            let encryptedData = processedData.zmEncryptPrefixingPlainTextIVWithKey(otrKey)
            let sha256 = encryptedData.zmSHA256Digest()
            let encryptionKeys = ZMImageAssetEncryptionKeys(otrKey: otrKey, sha256: sha256)
            genericMessage[format] = ZMGenericMessage(
                mediumImageProperties: storeProcessed ? self.sampleImageProperties(.Medium) : nil,
                processedImageProperties: storeProcessed ? self.sampleImageProperties(format) : nil,
                encryptionKeys: storeEncrypted ? encryptionKeys : nil,
                nonce: nonce.transportString(),
                format: format)
            
            if(storeProcessed) {
                directory.storeAssetData(nonce, format: format, encrypted: false, data: processedData)
            }
            if(storeEncrypted) {
                directory.storeAssetData(nonce, format: format, encrypted: true, data: encryptedData)
            }
        }
        
        if(storeOriginal) {
            directory.storeAssetData(nonce, format: .Original, encrypted: false, data: imageData)
        }
        let assetMessage = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        assetMessage.addGenericMessage(genericMessage[.Preview]!)
        assetMessage.addGenericMessage(genericMessage[.Medium]!)
        assetMessage.assetId = nonce
        return assetMessage
    }

    func testThatOriginalImageDataReturnsTheOriginalFileIfTheFileIsPresent() {
        // given
        let expectedData = self.sampleImageData()
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false, imageData: expectedData)
        
        // when
        let data = sut.originalImageData()
        
        // then
        XCTAssertNotNil(data)
        XCTAssertEqual(data.hash, expectedData.hash)
    }

    func testThatOriginalImageDataReturnsNilIfThereIsNoFile() {
        // given
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertNil(sut.originalImageData())
    }

    func testThatIsPublicForFormatReturnsNoForAllFormats() {
        // given
        let formats = [ZMImageFormat.Medium, ZMImageFormat.Invalid, ZMImageFormat.Original, ZMImageFormat.Preview, ZMImageFormat.Profile]
        
        // when
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        for format in formats {
            XCTAssertFalse(sut.isPublicForFormat(format))
        }
    }

    func testThatEncryptedDataForFormatReturnsValuesFromEncryptedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            // when
            let data = message.imageDataForFormat(format, encrypted: true)
            
            // then
            let dataOnFile = AssetDirectory().assetData(message.nonce, format: format, encrypted: true)
            AssertOptionalEqual(dataOnFile, expression2: data)
        }
    }
    
    func testThatImageDataForFormatReturnsValuesFromProcessedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            // when
            let data = message.imageDataForFormat(format, encrypted: false)
            
            // then
            let dataOnFile = AssetDirectory().assetData(message.nonce, format:format, encrypted: false)
            AssertOptionalEqual(dataOnFile, expression2: data)
        }
    }
    
    func testThatImageDataForFormatReturnsNilWhenThereIsNoFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        for format in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            
            // when
            let plainData = message.imageDataForFormat(format, encrypted: false)
            let encryptedData = message.imageDataForFormat(format, encrypted: true)
            
            // then
            XCTAssertNil(plainData)
            XCTAssertNil(encryptedData)
            
        }
    }

    func testThatItReturnsTheOriginalImageSize() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        for _ in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            
            // when
            let originalSize = message.originalImageSize()
            
            // then
            XCTAssertEqual(originalSize, self.sampleImageProperties(.Medium).size)
            
        }
    }
    
    func testThatItReturnsZeroOriginalImageSizeIfItWasNotSet() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        for _ in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            
            // when
            let originalSize = message.originalImageSize()
            
            // then
            XCTAssertEqual(originalSize, CGSizeMake(0,0))
            
        }
    }
    
    func testThatItReturnsTheRightRequiredImageFormats() {
        
        // given
        let expected = NSOrderedSet(array: [ZMImageFormat.Medium, ZMImageFormat.Preview].map { NSNumber(unsignedLong: $0.rawValue)})
        
        // when
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertEqual(message.requiredImageFormats(), expected);

    }
    
    func testThatItReturnsTheRightValueForInlineForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        XCTAssertFalse(message.isInlineForFormat(.Medium));
        XCTAssertTrue(message.isInlineForFormat(.Preview));
        XCTAssertFalse(message.isInlineForFormat(.Original));
        XCTAssertFalse(message.isInlineForFormat(.Profile));
        XCTAssertFalse(message.isInlineForFormat(.Invalid));
    }

    func testThatItReturnsTheRightValueForUsingNativePushForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertTrue(message.isUsingNativePushForFormat(.Medium));
        XCTAssertFalse(message.isUsingNativePushForFormat(.Preview));
        XCTAssertFalse(message.isUsingNativePushForFormat(.Original));
        XCTAssertFalse(message.isUsingNativePushForFormat(.Profile));
        XCTAssertFalse(message.isUsingNativePushForFormat(.Invalid));
    }
    
    func testThatItClearsOnlyTheOriginalImageFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: true, storeProcessed: true)
        
        // when
        message.processingDidFinish()
        
        // then
        let directory = AssetDirectory()
        XCTAssertNil(directory.assetData(message.nonce, format: .Original, encrypted: false))
        XCTAssertNil(message.originalImageData())
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Medium, encrypted: false))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Preview, encrypted: false))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Medium, encrypted: true))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Preview, encrypted: true))
    }

    func testThatItSetsTheCorrectImageDataPropertiesWhenSettingTheData() {
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            let testData = "foobar".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
            
            // when
            message.setImageData(testData, forFormat: format, properties: testProperties)
            
            // then
            XCTAssertEqual(message.genericMessageForFormat(format).image.width, 33)
            XCTAssertEqual(message.genericMessageForFormat(format).image.height, 55)
            XCTAssertEqual(message.genericMessageForFormat(format).image.size, 10)
            XCTAssertEqual(message.genericMessageForFormat(format).image.mimeType, "image/tiff")
        }
    }
    
    func testThatItStoresTheRightEncryptionKeysNoMatterInWhichOrderTheDataIsSet() {
        
        // given
        let dataPreview = "FOOOOOO".dataUsingEncoding(NSUTF8StringEncoding)
        let dataMedium = "xxxxxxxxx".dataUsingEncoding(NSUTF8StringEncoding)
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.setImageData(dataPreview, forFormat: .Preview, properties: testProperties) // simulate various order of setting
        message.setImageData(dataMedium, forFormat: .Medium, properties: testProperties)
        message.setImageData(dataPreview, forFormat: .Preview, properties: testProperties)
        message.setImageData(dataMedium, forFormat: .Medium, properties: testProperties)

        // then
        let dataOnDiskForPreview = AssetDirectory().assetData(message.nonce, format: .Preview, encrypted: true)!
        let dataOnDiskForMedium = AssetDirectory().assetData(message.nonce, format: .Medium, encrypted: true)!
        
        XCTAssertEqual(dataOnDiskForPreview.zmSHA256Digest(), message.previewGenericMessage.image.sha256)
        XCTAssertEqual(dataOnDiskForMedium.zmSHA256Digest(), message.mediumGenericMessage.image.sha256)
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetPreviewFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let testMediumProperties = ZMIImageProperties(size: CGSizeMake(111,100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSizeMake(80,55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.setImageData(testData, forFormat: .Preview, properties: testPreviewProperties)
        message.setImageData(testData, forFormat: .Medium, properties: testMediumProperties)
        
        // then
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.originalWidth, 111)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.originalHeight, 100)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.width, 80)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.height, 55)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.size, 10)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.mimeType, "image/tiff")
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.originalWidth, 111)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.originalHeight, 100)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.width, 111)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.height, 100)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.size, 1000)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.mimeType, "image/tiff")
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetMediumFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let testMediumProperties = ZMIImageProperties(size: CGSizeMake(111,100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSizeMake(80,55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.setImageData(testData, forFormat: .Medium, properties: testMediumProperties)
        message.setImageData(testData, forFormat: .Preview, properties: testPreviewProperties)
        
        // then
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.originalWidth, 111)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.originalHeight, 100)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.width, 80)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.height, 55)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.size, 10)
        XCTAssertEqual(message.genericMessageForFormat(.Preview).image.mimeType, "image/tiff")
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.originalWidth, 111)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.originalHeight, 100)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.width, 111)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.height, 100)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.size, 1000)
        XCTAssertEqual(message.genericMessageForFormat(.Medium).image.mimeType, "image/tiff")
    }
    
    func testThatItSavesTheImageDataToFileInPlainTextAndNotEncryptedWhenSettingTheDataOnAPlainTextMessage() {
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            message.isEncrypted = false
            let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")

            // when
            message.setImageData(sampleProcessedImageData(format), forFormat: format, properties: testProperties)
            
            // then
            AssertOptionalEqual(AssetDirectory().assetData(message.nonce, format: format, encrypted: false), expression2: sampleProcessedImageData(format))
            XCTAssertEqual(message.imageDataForFormat(format, encrypted: false), sampleProcessedImageData(format))
            AssertOptionalNil(AssetDirectory().assetData(message.nonce, format: format, encrypted: true))
            XCTAssertNil(message.imageDataForFormat(format, encrypted: true))
        }
    }
    
    func testThatItSavesTheImageDataToFileInPlainTextAndEncryptedWhenSettingTheDataOnAnEncryptedMessage() {
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            message.isEncrypted = true
            let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
            let data = sampleProcessedImageData(format)
            
            // when
            message.setImageData(data, forFormat: format, properties: testProperties)
            
            // then
            AssertOptionalEqual(AssetDirectory().assetData(message.nonce, format: format, encrypted: false), expression2: data)
            XCTAssertEqual(message.imageDataForFormat(format, encrypted: false), data)
            AssertOptionalNotNil(AssetDirectory().assetData(message.nonce, format: format, encrypted: true)) {
                let decrypted = $0.zmDecryptPrefixedPlainTextIVWithKey(message.genericMessageForFormat(format).image.otrKey)
                let sha = $0.zmSHA256Digest()
                XCTAssertEqual(decrypted, data)
                XCTAssertEqual(sha, message.genericMessageForFormat(format).image.sha256)
            }
        }
    }

    func testThatItReturnsNilEncryptedDataIfTheImageIsNotEncrypted() {

        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
            
            // then
            XCTAssertNil(message.imageDataForFormat(format, encrypted: true))
        }
    }
    
    func testThatItReturnsImageDataIdentifier() {
        // given
        let message1 = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        let message2 = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // when
        let id1 = message1.imageMessageData.imageDataIdentifier
        let id2 = message2.imageMessageData.imageDataIdentifier
        
        
        // then
        XCTAssertNotNil(id1)
        XCTAssertNotNil(id2)
        XCTAssertNotEqual(id1, id2)
        
        XCTAssertEqual(id1, message1.imageMessageData.imageDataIdentifier) // not random!
    }
    
    func testThatImageDataIdentifierChangesWhenChangingProcessedImage() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        let oldId = message.imageMessageData.imageDataIdentifier
        let properties = ZMIImageProperties(size: CGSizeMake(300,300), length: 234, mimeType: "image/jpg")
        
        // when
        message.setImageData(self.verySmallJPEGData(), forFormat: .Medium, properties: properties)
        
        // then
        let id = message.imageMessageData.imageDataIdentifier
        XCTAssertNotEqual(id, oldId)
    }
}


// MARK: - UpdateEvents
extension ZMAssetClientMessageTests {
    
    func testThatItCreatesOTRAssetMessagesFromMediumUpdateEvent() {
        let previewAssetId = NSUUID.createUUID()
        let mediumAssetId = NSUUID.createUUID()
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {

            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
            conversation.remoteIdentifier = NSUUID.createUUID()
            let nonce = NSUUID.createUUID()
            let imageData = self.verySmallJPEGData()
            let assetId = format == .Medium ? mediumAssetId : previewAssetId
            let genericMessage = ZMGenericMessage(imageData: imageData, format: format, nonce: nonce.transportString())
            let dataPayload = [
                "info" : genericMessage.data().base64String,
                "id" : assetId.transportString()
            ]
            
            let payload = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload)
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
            
            // when
            var sut : ZMAssetClientMessage? = nil
            self.performPretendingUiMocIsSyncMoc { () -> Void in
                sut = ZMAssetClientMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
            }
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertEqual(sut!.conversation, conversation)
            XCTAssertEqual(sut!.sender.remoteIdentifier!.transportString(), payload["from"] as? String)
            XCTAssertEqual(sut!.serverTimestamp.transportString(), payload["time"] as? String)
            
            XCTAssertTrue(sut!.isEncrypted)
            XCTAssertFalse(sut!.isPlainText)
            XCTAssertEqual(sut!.nonce, nonce)
            XCTAssertEqual(sut!.genericMessageForFormat(format).data(), genericMessage.data())
            XCTAssertEqual(sut!.assetId, format == .Medium ? mediumAssetId : nil)
        }
    }
}

// MARK: - GIF Data
extension ZMAssetClientMessageTests {
    
    func testThatIsNotAnAnimatedGifWhenItHasNoMediumData() {
        
        // given
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
        let data = sampleProcessedImageData(.Preview)
        
        // when
        message.setImageData(data, forFormat: .Preview, properties: testProperties)
        
        // then
        XCTAssertFalse(message.imageMessageData.isAnimatedGIF);
    }
}
