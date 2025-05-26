//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import KaliumBackup
import Testing
import WireFoundation

@testable import WireBackup

struct BackupImporterTests {

    private let password = "Cp2mXgrj.3-qX92p3BRG"

    @Test(arguments: [
        "android-encrypted",
        "android-unencrypted",
        "ios-encrypted",
        "ios-unencrypted",
        "web-encrypted",
        "web-unencrypted"
    ])
    func testPeekingIntoBackupFilesFromAllPlatforms(resource: String) async throws {

        let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        defer { try? FileManager.default.removeItem(at: workDirectoryURL) }

        let importer = BackupImporter(
            selfUserID: QualifiedID(
                id: UUID(uuidString: "cfc7f55a-2ccf-4557-b212-32b2c89bf1a2")!,
                domain: "staging.zinfra.io"
            ),
            workDirectoryURL: workDirectoryURL,
            fileUnarchiver: ZIPFoundationFileUnarchiver()
        )

        let backupURL = try #require(Bundle.module.url(forResource: resource, withExtension: "wbu"))
        let result = try await importer.peek(into: backupURL)

        #expect(result.isEncrypted == resource.hasSuffix("-encrypted"))
        #expect(result.version == "4")

    }

    // TODO: [WPB-16658] add more tests

    @Test(arguments: [
        "android-encrypted",
        "android-unencrypted",
        "ios-encrypted",
        "ios-unencrypted",
        "web-encrypted",
        "web-unencrypted"
    ])
    func testImportingBackupFilesFromAllPlatforms(resource: String) async throws {

        let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        defer { try? FileManager.default.removeItem(at: workDirectoryURL) }

        let importer = BackupImporter(
            selfUserID: QualifiedID(
                id: UUID(uuidString: "cfc7f55a-2ccf-4557-b212-32b2c89bf1a2")!,
                domain: "staging.zinfra.io"
            ),
            workDirectoryURL: workDirectoryURL,
            fileUnarchiver: ZIPFoundationFileUnarchiver()
        )

        let backupURL = try #require(Bundle.module.url(forResource: resource, withExtension: "wbu"))
        let password = resource.hasSuffix("-encrypted") ? password : ""
        let result = try await importer.importBackup(from: backupURL, using: password)
        let users = [BackupUser](result.usersPager).compactMap(UserBackupModel.init)
        let conversations = [BackupConversation](result.conversationsPager).compactMap(ConversationBackupModel.init)
        let messages = [BackupMessage](result.messagesPager).compactMap(MessageBackupModel.init)

        #expect(users.count == 1)
        if !resource.hasPrefix("web-") { // web stored different values at the time of writing this test
            #expect(users.first?.qualifiedID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io")
            #expect(users.first?.name == "CA Staging 94")
        }
        #expect(users.first?.handle == "ca-staging-94")

        #expect(conversations.count == 3) // one conversation, two self-conversations
        #expect(conversations.contains(
            ConversationBackupModel(
                qualifiedID: "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io",
                name: "Group-without-participants"
            )
        ))

        #expect(messages.count == 8)
        #expect(messages.contains(
            MessageBackupModel(
                id: "98316ad9-0cd1-4aa6-9151-b74eb05255d0",
                conversationID: "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io",
                senderUserID: "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io",
                senderClientID: nil,
                creationDate: try Date.ISO8601FormatStyle().parse("2025-05-16T07:29:30+0000"),
                content: .text(.init(text: "Simple text message"))
            )
        ))
/*
        0 :
        MessageBackupModel

        1 : MessageBackupModel(id: "e990d646-9943-4e1e-8195-ec77a1ba6427", conversationID: 7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io, senderUserID: CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io, senderClientID: nil, creationDate: 2025-05-16 07:29:39 +0000, content: WireBackup.MessageBackupModel.Content.text(WireBackup.MessageBackupModel.Content.TextContent(text: "Self deleting message")))
        MessageBackupModel

        2 : MessageBackupModel(id: "e44c5594-5c98-4567-8e54-95804cac7407", conversationID: 7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io, senderUserID: CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io, senderClientID: nil, creationDate: 2025-05-16 07:30:56 +0000, content: WireBackup.MessageBackupModel.Content.asset(WireBackup.MessageBackupModel.Content.AssetContent(mimeType: "image/jpeg", size: 165, name: Optional(""), otrKey: 32 bytes, sha256: 32 bytes, assetID: "3-5-22ab06d5-a12d-4e0d-bbd4-50b2bf9c2e95", assetToken: Optional(""), assetDomain: Optional("staging.zinfra.io"), encryption: nil, metadata: Optional(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.image(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.ImageMetadata(width: 320, height: 320, tag: Optional("medium")))))))
        MessageBackupModel

        3 : MessageBackupModel(id: "61bc2d96-fb9c-49da-be1a-2e1f1a82f319", conversationID: 7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io, senderUserID: CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io, senderClientID: nil, creationDate: 2025-05-16 07:31:13 +0000, content: WireBackup.MessageBackupModel.Content.asset(WireBackup.MessageBackupModel.Content.AssetContent(mimeType: "image/jpeg", size: 203, name: Optional("canary Small as file.jpeg"), otrKey: 32 bytes, sha256: 32 bytes, assetID: "3-5-188eb05a-f398-467a-8799-074b45a10672", assetToken: Optional(""), assetDomain: Optional("staging.zinfra.io"), encryption: nil, metadata: Optional(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.generic(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.GenericMetadata(name: Optional("canary Small as file.jpeg")))))))
        MessageBackupModel

        4 : MessageBackupModel(id: "ea88c152-f6c7-42d7-89e4-c4cbccfcb7b2", conversationID: 7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io, senderUserID: CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io, senderClientID: Optional("42e1057581213ae6"), creationDate: 2025-05-16 07:32:55 +0000, content: WireBackup.MessageBackupModel.Content.text(WireBackup.MessageBackupModel.Content.TextContent(text: "Edited message")))
        MessageBackupModel

        5 : MessageBackupModel(id: "23d0ebe1-13f2-44e1-a699-1f511764243f", conversationID: 7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io, senderUserID: CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io, senderClientID: Optional("42e1057581213ae6"), creationDate: 2025-05-16 07:33:22 +0000, content: WireBackup.MessageBackupModel.Content.asset(WireBackup.MessageBackupModel.Content.AssetContent(mimeType: "audio/mp4", size: 244, name: Optional("wire-audio-2025-05-16-09-33-11.mp4"), otrKey: 32 bytes, sha256: 32 bytes, assetID: "3-2-da7f6a06-6544-4881-bfb7-837ec81b2ff4", assetToken: Optional("a87ztkPJdNC2-hDyH-I4IQ=="), assetDomain: Optional("staging.zinfra.io"), encryption: nil, metadata: Optional(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.generic(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.GenericMetadata(name: Optional("wire-audio-2025-05-16-09-33-11.mp4")))))))
        MessageBackupModel

        6 : MessageBackupModel(id: "455a8a6c-acbb-4cbe-ae48-04b9a7643f91", conversationID: 7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io, senderUserID: CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io, senderClientID: Optional("42e1057581213ae6"), creationDate: 2025-05-16 07:33:39 +0000, content: WireBackup.MessageBackupModel.Content.asset(WireBackup.MessageBackupModel.Content.AssetContent(mimeType: "video/mp4", size: 216, name: Optional("video_attachment.mp4"), otrKey: 32 bytes, sha256: 32 bytes, assetID: "3-2-393a8608-1f64-4907-87b0-92409cb75999", assetToken: Optional("gwyOSFD8twOWoCkZXzIo6Q=="), assetDomain: Optional("staging.zinfra.io"), encryption: nil, metadata: Optional(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.generic(WireBackup.MessageBackupModel.Content.AssetContent.Metadata.GenericMetadata(name: Optional("video_attachment.mp4")))))))
        MessageBackupModel
*/
    }

}
