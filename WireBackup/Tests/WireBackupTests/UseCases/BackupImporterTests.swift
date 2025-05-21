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

//        #expect(result.totalPagesCount == 3)
//        #expect(result.usersPager.totalPages == 1)
//        #expect(result.conversationsPager.totalPages == 1)
//        #expect(result.messagesPager.totalPages == 1)
//
//        let users = result.usersPager.nextPage()
//        let conversations = result.conversationsPager.nextPage()
//        let messages = result.messagesPager.nextPage()

        #expect(users.count == 1)
        if !resource.hasPrefix("web-") { // some mismatch
            #expect(users.first?.qualifiedID == "CFC7F55A-2CCF-4557-B212-32B2C89BF1A2@staging.zinfra.io")
            #expect(users.first?.name == "CA Staging 94")
        }
        #expect(users.first?.handle == "ca-staging-94")

//        #expect(conversations.size == 3)
//        #expect(messages.size == 7)
//
//        let user = UserBackupModel(users.get(index: 0))
//        user.

        #expect(Bool(false))

    }

}
