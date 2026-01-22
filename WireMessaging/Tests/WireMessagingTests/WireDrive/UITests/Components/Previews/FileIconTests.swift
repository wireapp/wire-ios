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

@testable import WireMessagingUI

struct FileIconTests {

    @Test(arguments: [
        (type: UTType.archive, expected: FileIcon.archive),
        (type: UTType.audio, expected: FileIcon.audio),
        (type: UTType.script, expected: FileIcon.code),
        (type: UTType.sourceCode, expected: FileIcon.code),
        (type: UTType.xml, expected: FileIcon.code),
        (type: UTType.html, expected: FileIcon.code),
        (type: UTType.json, expected: FileIcon.code),
        (type: UTType.image, expected: FileIcon.image),
        (type: UTType.pdf, expected: FileIcon.pdf),
        (type: UTType.presentation, expected: FileIcon.presentation),
        (type: UTType.spreadsheet, expected: FileIcon.spreadsheet),
        (type: UTType.movie, expected: FileIcon.video),
        (type: UTType.text, expected: FileIcon.other)
    ])
    func makeFileIconWithUTType(type: UTType, expectedIcon: FileIcon) {
        #expect(FileIcon.make(type: type, fileExtension: nil) == expectedIcon)
    }

    @Test(arguments: [
        // Test document extensions
        (extension: "doc", expected: FileIcon.document),
        (extension: "docx", expected: FileIcon.document),
        (extension: "dot", expected: FileIcon.document),
        (extension: "dotx", expected: FileIcon.document),
        (extension: "odt", expected: FileIcon.document),
        (extension: "ott", expected: FileIcon.document),
        (extension: "rtf", expected: FileIcon.document),
        // Test code extensions
        (extension: "css", expected: FileIcon.code),
        (extension: "phtml", expected: FileIcon.code),
        (extension: "sparql", expected: FileIcon.code),
        (extension: "cs", expected: FileIcon.code),
        (extension: "java", expected: FileIcon.code),
        (extension: "jsp", expected: FileIcon.code),
        (extension: "sql", expected: FileIcon.code),
        (extension: "cgi", expected: FileIcon.code),
        (extension: "pl", expected: FileIcon.code),
        (extension: "inc", expected: FileIcon.code),
        (extension: "xsl", expected: FileIcon.code),
        // Test case insensitivity
        (extension: "DOCX", expected: FileIcon.document),
        (extension: "Java", expected: FileIcon.code),
        // Test unknown extension (should default to .other)
        (extension: "foo", expected: FileIcon.other)
    ])
    func makeFileIconWithExtension(fileExtension: String, expectedIcon: FileIcon) {
        #expect(FileIcon.make(type: nil, fileExtension: fileExtension) == expectedIcon)
    }

    @Test
    func makeFileIconPrecedence() {
        // Test that type takes precedence over extension
        #expect(FileIcon.make(type: .audio, fileExtension: "doc") == .audio)
        #expect(FileIcon.make(type: .image, fileExtension: "java") == .image)

        // Test fallback to extension when type doesn't match
        let customType = UTType(filenameExtension: "custom")
        #expect(FileIcon.make(type: customType, fileExtension: "doc") == .document)

        // Test fallback to .other when neither matches
        #expect(FileIcon.make(type: customType, fileExtension: "unknown") == .other)
        #expect(FileIcon.make(type: nil, fileExtension: nil) == .other)
    }

}
