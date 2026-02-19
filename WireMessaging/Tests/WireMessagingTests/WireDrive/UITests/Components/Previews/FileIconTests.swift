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

import Testing
import UniformTypeIdentifiers
import WireMessagingDomain

@testable import WireMessagingUI

struct FileIconTests {

    @Test(arguments: [
        (type: UTType.archive, expected: WireDriveFileType.archive),
        (type: UTType.audio, expected: WireDriveFileType.audio),
        (type: UTType.script, expected: WireDriveFileType.code),
        (type: UTType.sourceCode, expected: WireDriveFileType.code),
        (type: UTType.xml, expected: WireDriveFileType.code),
        (type: UTType.html, expected: WireDriveFileType.code),
        (type: UTType.json, expected: WireDriveFileType.code),
        (type: UTType.image, expected: WireDriveFileType.image),
        (type: UTType.pdf, expected: WireDriveFileType.pdf),
        (type: UTType.presentation, expected: WireDriveFileType.presentation),
        (type: UTType.spreadsheet, expected: WireDriveFileType.spreadsheet),
        (type: UTType.movie, expected: WireDriveFileType.video),
        (type: UTType.text, expected: WireDriveFileType.other)
    ])
    func makeFileIconWithUTType(type: UTType, expectedIcon: WireDriveFileType) {
        #expect(WireDriveFileType.make(type: type, fileExtension: nil) == expectedIcon)
    }

    @Test(arguments: [
        // Test document extensions
        (extension: "doc", expected: WireDriveFileType.document),
        (extension: "docx", expected: WireDriveFileType.document),
        (extension: "dot", expected: WireDriveFileType.document),
        (extension: "dotx", expected: WireDriveFileType.document),
        (extension: "odt", expected: WireDriveFileType.document),
        (extension: "ott", expected: WireDriveFileType.document),
        (extension: "rtf", expected: WireDriveFileType.document),
        // Test code extensions
        (extension: "css", expected: WireDriveFileType.code),
        (extension: "phtml", expected: WireDriveFileType.code),
        (extension: "sparql", expected: WireDriveFileType.code),
        (extension: "cs", expected: WireDriveFileType.code),
        (extension: "java", expected: WireDriveFileType.code),
        (extension: "jsp", expected: WireDriveFileType.code),
        (extension: "sql", expected: WireDriveFileType.code),
        (extension: "cgi", expected: WireDriveFileType.code),
        (extension: "pl", expected: WireDriveFileType.code),
        (extension: "inc", expected: WireDriveFileType.code),
        (extension: "xsl", expected: WireDriveFileType.code),
        // Test case insensitivity
        (extension: "DOCX", expected: WireDriveFileType.document),
        (extension: "Java", expected: WireDriveFileType.code),
        // Test unknown extension (should default to .other)
        (extension: "foo", expected: WireDriveFileType.other)
    ])
    func makeFileIconWithExtension(fileExtension: String, expectedIcon: WireDriveFileType) {
        #expect(WireDriveFileType.make(type: nil, fileExtension: fileExtension) == expectedIcon)
    }

    @Test
    func makeFileIconPrecedence() {
        // Test that type takes precedence over extension
        #expect(WireDriveFileType.make(type: .audio, fileExtension: "doc") == .audio)
        #expect(WireDriveFileType.make(type: .image, fileExtension: "java") == .image)

        // Test fallback to extension when type doesn't match
        let customType = UTType(filenameExtension: "custom")
        #expect(WireDriveFileType.make(type: customType, fileExtension: "doc") == .document)

        // Test fallback to .other when neither matches
        #expect(WireDriveFileType.make(type: customType, fileExtension: "unknown") == .other)
        #expect(WireDriveFileType.make(type: nil, fileExtension: nil) == .other)
    }

}
