//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import GenericMessageProtocol
import Testing
import WireDataModel
import WireNetwork

@testable import WireDomain

@Suite("ProtobufMessageDecoder")
struct ProtobufMessageDecoderTests {

    let sut = ProtobufMessageDecoder()

    // MARK: - extractMLSMessageContent

    @Test("Valid base64 returns a GenericMessage")
    func extractMLSMessageContent_validMessage_returnsGenericMessage() throws {
        let result = try sut.extractMLSMessageContent(from: Scaffolding.validBase64)
        #expect(result.content != nil)
    }

    @Test("Invalid base64 throws failedToDecodeGenericMessage")
    func extractMLSMessageContent_invalidBase64_throwsFailedToDecode() {
        let error = #expect(throws: ProtobufMessageDecoder.Failure.self) {
            try sut.extractMLSMessageContent(from: "not!valid!base64!")
        }
        #expect(error == .failedToDecodeGenericMessage)
    }

    // MARK: - extractProteusMessageContent

    @Test("Regular message without externalData returns a GenericMessage")
    func extractProteusMessageContent_regularMessage_returnsMessage() throws {
        let result = try sut.extractProteusMessageContent(
            from: Scaffolding.validBase64,
            externalData: nil
        )
        #expect(result.content != nil)
    }

    @Test("Regular message ignores any provided externalData")
    func extractProteusMessageContent_regularMessage_externalDataIsIgnored() throws {
        let result = try sut.extractProteusMessageContent(
            from: Scaffolding.validBase64,
            externalData: MessageContent(encryptedMessage: "irrelevant-data")
        )
        #expect(result.content != nil)
    }

    @Test("External message with valid data returns the inner GenericMessage")
    func extractProteusMessageContent_externalMessage_validData_returnsInnerMessage() throws {
        let payload = try Scaffolding.ExternalPayload.make()

        let result = try sut.extractProteusMessageContent(
            from: payload.outerBase64,
            externalData: MessageContent(encryptedMessage: payload.externalDataBase64)
        )

        #expect(result.text.content == Scaffolding.innerMessageText)
    }

    @Test("External message without externalData throws externalProteusDataMissing")
    func extractProteusMessageContent_externalMessage_missingData_throwsMissing() throws {
        let payload = try Scaffolding.ExternalPayload.make()

        let error = #expect(throws: ProtobufMessageDecoder.Failure.self) {
            try sut.extractProteusMessageContent(from: payload.outerBase64, externalData: nil)
        }
        #expect(error == .externalProteusDataMissing)
    }

    @Test("External message with invalid base64 data throws failedToDecodeExternalProteusData")
    func extractProteusMessageContent_externalMessage_invalidBase64Data_throwsDecodeFailed() throws {
        let payload = try Scaffolding.ExternalPayload.make()

        let error = #expect(throws: ProtobufMessageDecoder.Failure.self) {
            try sut.extractProteusMessageContent(
                from: payload.outerBase64,
                externalData: MessageContent(encryptedMessage: "!not-valid-base64!")
            )
        }
        #expect(error == .failedToDecodeExternalProteusData)
    }

    @Test("External message with tampered SHA throws externalProteusDataSHAMismatch")
    func extractProteusMessageContent_externalMessage_wrongSHA_throwsSHAMismatch() throws {
        let payload = try Scaffolding.ExternalPayload.make()

        let tampered = GenericMessage.with {
            $0.messageID = UUID().uuidString
            $0.external = External.with {
                $0.otrKey = payload.otrKey
                $0.sha256 = Data(repeating: 0xFF, count: 32)
            }
        }
        let tamperedBase64 = try tampered.serializedData().base64EncodedString()

        let error = #expect(throws: ProtobufMessageDecoder.Failure.self) {
            try sut.extractProteusMessageContent(
                from: tamperedBase64,
                externalData: MessageContent(encryptedMessage: payload.externalDataBase64)
            )
        }
        #expect(error == .externalProteusDataSHAMismatch)
    }

    @Test("External message with wrong decryption key throws failedToDecryptExternalProteusData")
    func extractProteusMessageContent_externalMessage_wrongKey_throwsDecryptFailed() throws {
        let payload = try Scaffolding.ExternalPayload.make()
        let wrongKey = try #require(NSData.randomEncryptionKey())

        // SHA is correct so the hash check passes, but the wrong key causes decryption to fail
        let tampered = GenericMessage.with {
            $0.messageID = UUID().uuidString
            $0.external = External.with {
                $0.otrKey = wrongKey
                $0.sha256 = payload.sha256
            }
        }
        let tamperedBase64 = try tampered.serializedData().base64EncodedString()

        let error = #expect(throws: ProtobufMessageDecoder.Failure.self) {
            try sut.extractProteusMessageContent(
                from: tamperedBase64,
                externalData: MessageContent(encryptedMessage: payload.externalDataBase64)
            )
        }
        #expect(error == .failedToDecryptExternalProteusData)
    }
}

// MARK: - Scaffolding

private enum Scaffolding {

    // A known valid base64-encoded GenericMessage containing a text field ("Everything").
    // Used consistently across the project as the canonical well-formed incoming message.
    static let validBase64 = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="

    static let innerMessageText = "hello from external"

    /// A fully constructed external Proteus payload for round-trip testing.
    struct ExternalPayload {
        let outerBase64: String
        let externalDataBase64: String
        let otrKey: Data
        let sha256: Data

        static func make() throws -> ExternalPayload {
            let inner = GenericMessage.with {
                $0.messageID = UUID().uuidString
                $0.text = Text.with { $0.content = innerMessageText }
            }

            let encrypted = try #require(GenericMessage.encryptedDataWithKeys(from: inner))
            let encryptedData = try #require(encrypted.data)
            let keys = try #require(encrypted.keys)

            let outer = GenericMessage.with {
                $0.messageID = UUID().uuidString
                $0.external = External.with {
                    $0.otrKey = keys.aesKey
                    $0.sha256 = keys.sha256
                }
            }

            return ExternalPayload(
                outerBase64: try outer.serializedData().base64EncodedString(),
                externalDataBase64: encryptedData.base64EncodedString(),
                otrKey: keys.aesKey,
                sha256: keys.sha256
            )
        }
    }
}
