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
public import SwiftUI
public import UniformTypeIdentifiers
public import WireMessagingDomain

extension WireDriveFileType {

    // MARK: - Factory

    /// Creates an instance based on the provided optional type and file extension.
    public static func make(type: UTType?, fileExtension: String?) -> WireDriveFileType {
        if let type, let icon = WireDriveFileType.make(type: type) {
            icon
        } else if let fileExtension, let icon = WireDriveFileType.make(fileExtension: fileExtension) {
            icon
        } else {
            .other
        }
    }

    private static func make(type: UTType) -> WireDriveFileType? {
        func icon(type: UTType) -> WireDriveFileType? {
            switch type {
            case .archive:
                .archive
            case .audio:
                .audio
            case .script, .sourceCode, .xml, .html, .json:
                .code
            case .image:
                .image
            case .pdf:
                .pdf
            case .presentation:
                .presentation
            case .spreadsheet:
                .spreadsheet
            case .movie:
                .video
            default:
                nil
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

    private static func make(fileExtension: String) -> WireDriveFileType? {
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

    var imageResource: ImageResource {
        switch self {
        case .archive:
            .fileIconArchive
        case .audio:
            .fileIconAudio
        case .code:
            .fileIconCode
        case .document:
            .fileIconDoc
        case .image:
            .fileIconImg
        case .other:
            .fileIconOther
        case .pdf:
            .fileIconPDF
        case .presentation:
            .fileIconPresentation
        case .spreadsheet:
            .fileIconSpreadsheet
        case .video:
            .fileIconVideo
        case .folder:
            .fileIconFolder
        }
    }

    public var image: UIImage {
        UIImage(resource: imageResource)
    }

}
