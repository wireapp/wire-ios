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
import SwiftUI
import UniformTypeIdentifiers

enum FileIcon {

    case archive
    case audio
    case code
    case document
    case image
    case other
    case pdf
    case presentation
    case spreadsheet
    case video

}

extension FileIcon {

    // MARK: - Factory

    /// Creates a `FileIcon` based on the provided optional type and file extension.

    static func make(type: UTType?, fileExtension: String?) -> FileIcon {
        if let type, let icon = FileIcon.make(type: type) {
            return icon
        } else if let fileExtension, let icon = FileIcon.make(fileExtension: fileExtension) {
            return icon
        } else {
            return .other
        }
    }

    private static func make(type: UTType) -> FileIcon? {
        func icon(type: UTType) -> FileIcon? {
            switch type {
            case .archive:
                return .archive
            case .audio:
                return .audio
            case .script, .sourceCode, .xml, .html, .json:
                return .code
            case .image:
                return .image
            case .pdf:
                return .pdf
            case .presentation:
                return .presentation
            case .spreadsheet:
                return .spreadsheet
            case .movie:
                return .video
            default:
                return nil
            }
        }

        var types = type.supertypes
        types.insert(type)

        for type in types {
            if let icon = icon(type: type) {
                return icon
            }
        }
        return nil
    }

    private static func make(fileExtension: String) -> FileIcon? {
        switch fileExtension.lowercased() {
        case "docx", "doc", "dotx", "dot", "odt", "ott", "rtf":
            .document
        case "css", "phtml", "sparql", "cs", "java", "jsp", "sql", "cgi", "pl", "inc", "xsl":
            .code
        default:
            nil
        }
    }

    // MARK: - Resource

    var resource: ImageResource {
        switch self {
        case .archive:
            return .fileIconArchive
        case .audio:
            return .fileIconAudio
        case .code:
            return .fileIconCode
        case .document:
            return .fileIconDoc
        case .image:
            return .fileIconImg
        case .other:
            return .fileIconOther
        case .pdf:
            return .fileIconPDF
        case .presentation:
            return .fileIconPresentation
        case .spreadsheet:
            return .fileIconSpreadsheet
        case .video:
            return .fileIconVideo
        }
    }

}
