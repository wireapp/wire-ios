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
        (type: UTType.archive, expected: FileType.archive),
        (type: UTType.audio, expected: FileType.audio),
        (type: UTType.script, expected: FileType.code),
        (type: UTType.sourceCode, expected: FileType.code),
        (type: UTType.xml, expected: FileType.code),
        (type: UTType.html, expected: FileType.code),
        (type: UTType.json, expected: FileType.code),
        (type: UTType.image, expected: FileType.image),
        (type: UTType.pdf, expected: FileType.pdf),
        (type: UTType.presentation, expected: FileType.presentation),
        (type: UTType.spreadsheet, expected: FileType.spreadsheet),
        (type: UTType.movie, expected: FileType.video),
        (type: UTType.text, expected: FileType.other)
    ])
    func makeFileIconWithUTType(type: UTType, expectedIcon: FileType) {
        #expect(FileType.make(type: type, fileExtension: nil) == expectedIcon)
    }

    @Test(arguments: [
        // Test document extensions
        (extension: "doc", expected: FileType.document),
        (extension: "docx", expected: FileType.document),
        (extension: "dot", expected: FileType.document),
        (extension: "dotx", expected: FileType.document),
        (extension: "odt", expected: FileType.document),
        (extension: "ott", expected: FileType.document),
        (extension: "rtf", expected: FileType.document),
        // Test code extensions
        (extension: "css", expected: FileType.code),
        (extension: "phtml", expected: FileType.code),
        (extension: "sparql", expected: FileType.code),
        (extension: "cs", expected: FileType.code),
        (extension: "java", expected: FileType.code),
        (extension: "jsp", expected: FileType.code),
        (extension: "sql", expected: FileType.code),
        (extension: "cgi", expected: FileType.code),
        (extension: "pl", expected: FileType.code),
        (extension: "inc", expected: FileType.code),
        (extension: "xsl", expected: FileType.code),
        // Test case insensitivity
        (extension: "DOCX", expected: FileType.document),
        (extension: "Java", expected: FileType.code),
        // Test unknown extension (should default to .other)
        (extension: "foo", expected: FileType.other)
    ])
    func makeFileIconWithExtension(fileExtension: String, expectedIcon: FileType) {
        #expect(FileType.make(type: nil, fileExtension: fileExtension) == expectedIcon)
    }

    @Test
    func makeFileIconPrecedence() {
        // Test that type takes precedence over extension
        #expect(FileType.make(type: .audio, fileExtension: "doc") == .audio)
        #expect(FileType.make(type: .image, fileExtension: "java") == .image)

        // Test fallback to extension when type doesn't match
        let customType = UTType(filenameExtension: "custom")
        #expect(FileType.make(type: customType, fileExtension: "doc") == .document)

        // Test fallback to .other when neither matches
        #expect(FileType.make(type: customType, fileExtension: "unknown") == .other)
        #expect(FileType.make(type: nil, fileExtension: nil) == .other)
    }

}
