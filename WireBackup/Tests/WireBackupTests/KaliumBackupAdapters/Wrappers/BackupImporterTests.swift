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
import KaliumBackup
import Testing
import WireFoundation
import WireUtilitiesPackage

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

    @Test(arguments: [
        "android-encrypted",
        "android-unencrypted",
        "ios-encrypted",
        "ios-unencrypted"
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
        #expect(users.first?.qualifiedID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io")
        #expect(users.first?.name == "CA Staging 94")
        #expect(users.first?.handle == "ca-staging-94")

        #expect(conversations.count == 3) // one conversation, two self-conversations
        #expect(conversations.contains(
            ConversationBackupModel(
                qualifiedID: "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io",
                name: "Group-without-participants"
            )
        ))

        #expect(messages.count == 8)
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:29:30+0000")
            return messageModel.id == "98316ad9-0cd1-4aa6-9151-b74eb05255d0" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content == .text(.init(text: "Simple text message"))
        }))
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:32:55+0000")
            return messageModel.id == "ea88c152-f6c7-42d7-89e4-c4cbccfcb7b2" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content == .text(.init(text: "Edited message"))
        }))
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:29:39+0000")
            return messageModel.id == "e990d646-9943-4e1e-8195-ec77a1ba6427" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content == .text(.init(text: "Self deleting message"))
        }))
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:32:05+0000")
            return messageModel.id == "3b535c3e-9648-467d-bc60-ac01dfac556b" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content == .location(.init(
                    longitude: 13.401895,
                    latitude: 52.523636,
                    name: "13, Sophienstraße, Berlin, City Centre, 10178",
                    zoom: 17
                ))
        }))
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:30:56+0000")
            return messageModel.id == "e44c5594-5c98-4567-8e54-95804cac7407" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content.assetContent?.mimeType == "image/jpeg" &&
                messageModel.content.assetContent?.size == 155 &&
                messageModel.content.assetContent?.otrKey.isEmpty == false &&
                messageModel.content.assetContent?.sha256.isEmpty == false &&
                messageModel.content.assetContent?.assetID == "3-5-22ab06d5-a12d-4e0d-bbd4-50b2bf9c2e95" &&
                messageModel.content.assetContent?.assetDomain == "staging.zinfra.io" &&
                messageModel.content.assetContent?.metadata?.imageMetadata?.width == 320 &&
                messageModel.content.assetContent?.metadata?.imageMetadata?.height == 320
        }))
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:31:13+0000")
            return messageModel.id == "61bc2d96-fb9c-49da-be1a-2e1f1a82f319" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content.assetContent?.mimeType == "image/jpeg" &&
                messageModel.content.assetContent?.size != nil &&
                messageModel.content.assetContent.map { $0.size >= 179 } == true &&
                messageModel.content.assetContent?.name == "canary Small as file.jpeg" &&
                messageModel.content.assetContent?.otrKey.isEmpty == false &&
                messageModel.content.assetContent?.sha256.isEmpty == false &&
                messageModel.content.assetContent?.assetID == "3-5-188eb05a-f398-467a-8799-074b45a10672" &&
                messageModel.content.assetContent?.assetDomain == "staging.zinfra.io"
        }))
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:33:22+0000")
            return messageModel.id == "23d0ebe1-13f2-44e1-a699-1f511764243f" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content.assetContent?.mimeType == "audio/mp4" &&
                messageModel.content.assetContent?.size != nil &&
                messageModel.content.assetContent.map { $0.size >= 180 } == true &&
                messageModel.content.assetContent?.otrKey.isEmpty == false &&
                messageModel.content.assetContent?.sha256.isEmpty == false &&
                messageModel.content.assetContent?.assetID == "3-2-da7f6a06-6544-4881-bfb7-837ec81b2ff4" &&
                messageModel.content.assetContent?.assetToken == "a87ztkPJdNC2-hDyH-I4IQ==" &&
                messageModel.content.assetContent?.assetDomain == "staging.zinfra.io" &&
                messageModel.content.assetContent?.encryption == .aesCBC &&
                messageModel.content.assetContent?.metadata?.audioMetadata?.normalization?.isEmpty != false &&
                messageModel.content.assetContent?.metadata?.audioMetadata?.duration == 6561
        }))
        #expect(messages.contains(where: { messageModel in
            let expectedCreationDate = try! Date.ISO8601FormatStyle().parse("2025-05-16T07:33:39+0000")
            return messageModel.id == "455a8a6c-acbb-4cbe-ae48-04b9a7643f91" &&
                messageModel.conversationID == "7E4143D8-C126-488B-B9DB-A0B419B767E9@staging.zinfra.io" &&
                messageModel.senderUserID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io" &&
                messageModel.creationDate == expectedCreationDate &&
                messageModel.content.assetContent?.mimeType == "video/mp4" &&
                messageModel.content.assetContent?.size != nil &&
                messageModel.content.assetContent?.name == "video_attachment.mp4" &&
                messageModel.content.assetContent.map { $0.size >= 180 } == true &&
                messageModel.content.assetContent?.otrKey.isEmpty == false &&
                messageModel.content.assetContent?.sha256.isEmpty == false &&
                messageModel.content.assetContent?.assetID == "3-2-393a8608-1f64-4907-87b0-92409cb75999" &&
                messageModel.content.assetContent?.assetToken == "gwyOSFD8twOWoCkZXzIo6Q==" &&
                messageModel.content.assetContent?.assetDomain == "staging.zinfra.io" &&
                messageModel.content.assetContent?.encryption == .aesCBC
        }))
    }

}

private extension MessageBackupModel.Content {
    var assetContent: AssetContent? {
        if case let .asset(assetContent) = self { assetContent } else { nil }
    }
}

private extension MessageBackupModel.Content.AssetContent.Metadata {
    var imageMetadata: ImageMetadata? {
        if case let .image(imageMetadata) = self { imageMetadata } else { nil }
    }

    var audioMetadata: AudioMetadata? {
        if case let .audio(audioMetadata) = self { audioMetadata } else { nil }
    }

    var videoMetadata: VideoMetadata? {
        if case let .video(videoMetadata) = self { videoMetadata } else { nil }
    }

    var genericMetadata: GenericMetadata? {
        if case let .generic(genericMetadata) = self { genericMetadata } else { nil }
    }
}
